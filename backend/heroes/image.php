<?php
include_once '../config/cors.php';

/**
 * Image proxy with an on-disk cache.
 *
 * WHY THIS EXISTS
 * ---------------
 * The heroes table and the News API both store third-party image URLs. Those
 * hosts do not send `Access-Control-Allow-Origin: *` (the Steam CDN answers with
 * `https://www.dota2.com`, and most news CDNs send no CORS header at all).
 * `Image.network` on Flutter web has to download and decode the bytes itself, so
 * the browser blocks those responses and every image falls back to a grey
 * placeholder. Serving the bytes from our own origin sidesteps CORS entirely.
 *
 * CACHING
 * -------
 * A busy grid would otherwise re-download every portrait on each scroll. Fetched
 * images are written to CACHE_DIR keyed by the SHA-256 of the source URL and
 * replayed from disk on later requests, which turns a network round trip into a
 * file read. Cached bytes are identical to what the CDN returned, so the SSRF
 * checks that gated the first fetch still describe what the proxy is willing to
 * serve. Append `&refresh=1` to bypass the cache for one request.
 *
 * SECURITY
 * --------
 * Fetching a caller-supplied URL is an SSRF risk, so every request is validated:
 * http/https only, ports 80/443 only, and every address the host resolves to
 * must be public. Both A and AAAA records are checked - validating only the A
 * record leaves cURL free to connect over IPv6 to an address nobody looked at.
 * Redirects are followed manually (up to 3 hops) so the checks are re-applied to
 * each hop - automatic following would let a public host bounce us into the
 * private network. Responses are capped at 5 MB and must be an image.
 *
 * Residual risk: the name is resolved once for validation and again by cURL when
 * it connects, so a DNS-rebinding attacker has a brief window. Closing it fully
 * means pinning the validated address with CURLOPT_RESOLVE.
 *
 * The cache directory holds only publicly fetchable images under a hashed name,
 * and is additionally blocked from direct web access by its own .htaccess.
 */

const MAX_REDIRECTS = 3;
const MAX_BYTES = 5 * 1024 * 1024;   // 5 MB
const TIMEOUT_SECONDS = 10;
const CACHE_TTL_SECONDS = 7 * 24 * 60 * 60;   // 7 days
const CACHE_MAX_ENTRIES = 500;
const BROWSER_MAX_AGE = 86400;                // 1 day

// Kept outside heroes/ so the cache is shared with the rest of the backend.
define('CACHE_DIR', __DIR__ . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . 'cache' . DIRECTORY_SEPARATOR . 'images');

function fail(int $code, string $message): void {
    http_response_code($code);
    echo json_encode(["message" => $message]);
    exit();
}

/** IPv4 ranges filter_var accepts but that are not publicly routable. */
function extra_blocked_ipv4_ranges(): array {
    return [
        ['100.64.0.0', 10],     // RFC 6598 CGNAT shared address space
        ['198.18.0.0', 15],     // RFC 2544 benchmarking
        ['192.0.2.0', 24],      // RFC 5737 TEST-NET-1
        ['198.51.100.0', 24],   // RFC 5737 TEST-NET-2
        ['203.0.113.0', 24],    // RFC 5737 TEST-NET-3
        ['192.88.99.0', 24],    // deprecated 6to4 relay anycast
    ];
}

/** True when $ip falls inside one of the extra blocked IPv4 ranges. */
function is_extra_blocked_ipv4(string $ip): bool {
    $value = ip2long($ip);
    if ($value === false) {
        return true;
    }
    $value = (int) $value;

    foreach (extra_blocked_ipv4_ranges() as [$base, $bits]) {
        $baseValue = (int) ip2long($base);
        $mask = $bits === 0 ? 0 : (0xFFFFFFFF << (32 - $bits)) & 0xFFFFFFFF;
        if (($value & $mask) === ($baseValue & $mask)) {
            return true;
        }
    }
    return false;
}

/**
 * IPv6 forms that tunnel a private IPv4 address, so checking only the outer
 * address would pass: ::ffff:a.b.c.d (IPv4-mapped), 64:ff9b::a.b.c.d (NAT64)
 * and 2002:xxxx:xxxx:: (6to4). filter_var reports all of these as public.
 */
function ipv6_embeds_blocked_ipv4(string $packed): bool {
    if (strlen($packed) !== 16) {
        return true;
    }

    $isMapped = substr($packed, 0, 12) === "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF";
    $isNat64  = substr($packed, 0, 12) === "\x00\x64\xFF\x9B\x00\x00\x00\x00\x00\x00\x00\x00";
    $is6to4   = substr($packed, 0, 2) === "\x20\x02";

    $offset = ($isMapped || $isNat64) ? 12 : ($is6to4 ? 2 : null);
    if ($offset === null) {
        return false;
    }

    $embedded = long2ip(unpack('N', substr($packed, $offset, 4))[1]);
    if (is_extra_blocked_ipv4($embedded)) {
        return true;
    }
    return filter_var(
        $embedded,
        FILTER_VALIDATE_IP,
        FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE
    ) === false;
}

/** True when $ip is routable on the public internet. */
function is_public_ip(string $ip): bool {
    if (filter_var($ip, FILTER_VALIDATE_IP) === false) {
        return false;
    }

    // NO_PRIV_RANGE covers 10/8, 172.16/12, 192.168/16, 127/8 and fc00::/7.
    // NO_RES_RANGE covers 0/8, 169.254/16, fe80::/10 and 240/4.
    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) === false) {
        return false;
    }

    $packed = @inet_pton($ip);
    if ($packed === false) {
        return false;
    }

    return strlen($packed) === 4
        ? !is_extra_blocked_ipv4($ip)
        : !ipv6_embeds_blocked_ipv4($packed);
}

/**
 * Every address $host resolves to, A and AAAA alike. cURL picks whichever the
 * network offers, so validating only one family would leave the other unchecked.
 */
function resolve_all_ips(string $host): array {
    $addresses = [];

    $ipv4 = @gethostbynamel($host);
    if (is_array($ipv4)) {
        foreach ($ipv4 as $ip) {
            $addresses[] = $ip;
        }
    }

    $ipv6 = @dns_get_record($host, DNS_AAAA);
    if (is_array($ipv6)) {
        foreach ($ipv6 as $record) {
            if (!empty($record['ipv6'])) {
                $addresses[] = $record['ipv6'];
            }
        }
    }

    return array_values(array_unique($addresses));
}

/**
 * Validates a URL, failing the request with a 4xx when it is not safe to fetch.
 * Rejects non-http(s) schemes, non-standard ports, and any host with an address
 * that is not publicly routable.
 */
function assert_safe_url(string $url): void {
    $parts = parse_url($url);
    if ($parts === false || empty($parts['scheme']) || empty($parts['host'])) {
        fail(400, "Malformed image URL.");
    }

    $scheme = strtolower($parts['scheme']);
    if ($scheme !== 'http' && $scheme !== 'https') {
        fail(400, "Only http and https URLs are allowed.");
    }

    $port = $parts['port'] ?? ($scheme === 'https' ? 443 : 80);
    if ($port !== 80 && $port !== 443) {
        fail(400, "Only ports 80 and 443 are allowed.");
    }

    $host = $parts['host'];

    // An IP literal is checked as-is; a hostname has to be resolved first.
    if (filter_var($host, FILTER_VALIDATE_IP) !== false) {
        if (!is_public_ip($host)) {
            fail(403, "Refusing to fetch a non-public address.");
        }
        return;
    }

    $addresses = resolve_all_ips($host);
    if (!$addresses) {
        fail(403, "Refusing to fetch a host that does not resolve.");
    }

    foreach ($addresses as $ip) {
        if (!is_public_ip($ip)) {
            fail(403, "Refusing to fetch a host that resolves to a non-public address.");
        }
    }
}

/**
 * Resolves a Location header against the URL it came from. Per RFC 7231 the
 * value may be absolute, protocol-relative ("//host/path") or a relative
 * reference, and the result is re-validated on the next hop either way.
 */
function resolve_location(string $base, string $location): string {
    if (preg_match('~^https?://~i', $location)) {
        return $location;
    }

    $parts = parse_url($base);
    if ($parts === false || empty($parts['scheme']) || empty($parts['host'])) {
        return $location;
    }

    $scheme = $parts['scheme'];
    $origin = $scheme . '://' . $parts['host'] . (isset($parts['port']) ? ':' . $parts['port'] : '');

    if (substr($location, 0, 2) === '//') {
        return $scheme . ':' . $location;
    }
    if (substr($location, 0, 1) === '/') {
        return $origin . $location;
    }

    $path = $parts['path'] ?? '/';
    $dir = substr($path, 0, strrpos($path, '/') + 1);
    return $origin . ($dir === '' ? '/' : $dir) . $location;
}

/** Returns the "image/..." part of a Content-Type, or null if it is not an image. */
function image_mime(?string $contentType): ?string {
    if ($contentType === null) {
        return null;
    }
    $mime = strtolower(trim(explode(';', $contentType)[0]));
    return strpos($mime, 'image/') === 0 ? $mime : null;
}

// ---------------------------------------------------------------------------
// Cache
// ---------------------------------------------------------------------------

function cache_file(string $url): string {
    return CACHE_DIR . DIRECTORY_SEPARATOR . hash('sha256', $url) . '.cache';
}

/**
 * Reads a cached image. Returns null on a miss, and also drops entries that are
 * expired or corrupt so a truncated write can never be served.
 */
function cache_read(string $file): ?array {
    if (!is_file($file)) {
        return null;
    }
    if (time() - (int) filemtime($file) > CACHE_TTL_SECONDS) {
        @unlink($file);
        return null;
    }

    $raw = @file_get_contents($file);
    if ($raw === false || $raw === '') {
        @unlink($file);
        return null;
    }

    // Layout: "<mime>\n" followed by the raw image bytes.
    $split = strpos($raw, "\n");
    if ($split === false) {
        @unlink($file);
        return null;
    }

    $mime = substr($raw, 0, $split);
    $body = substr($raw, $split + 1);
    if ($mime === '' || $body === '' || $mime !== image_mime($mime)) {
        @unlink($file);
        return null;
    }

    return ['mime' => $mime, 'body' => $body];
}

/**
 * Stores an image under $file. Writes to a temporary name and renames, because
 * rename() is atomic on the same filesystem - a reader never sees a half-written
 * entry, and a failed write leaves no corrupt file behind.
 */
function cache_write(string $file, string $mime, string $body): void {
    $dir = dirname($file);
    if (!is_dir($dir) && !@mkdir($dir, 0775, true) && !is_dir($dir)) {
        return;
    }
    if (is_file($file)) {
        return;   // another request already cached this URL
    }

    $tmp = $file . '.' . getmypid() . '.tmp';
    if (@file_put_contents($tmp, $mime . "\n" . $body, LOCK_EX) === false) {
        return;
    }
    if (!@rename($tmp, $file)) {
        @unlink($tmp);
    }
}

/**
 * Keeps the cache from growing without bound: drops expired entries and, if it is
 * still over CACHE_MAX_ENTRIES, evicts the oldest. Runs on a small random sample
 * of writes so pruning cost is spread out rather than paid on every request.
 */
function cache_prune(string $dir): void {
    if (mt_rand(1, 50) !== 1) {
        return;
    }

    $files = @glob($dir . DIRECTORY_SEPARATOR . '*.cache');
    if ($files === false) {
        return;
    }

    $now = time();
    $live = [];
    foreach ($files as $file) {
        if ($now - (int) filemtime($file) > CACHE_TTL_SECONDS) {
            @unlink($file);
        } else {
            $live[] = $file;
        }
    }

    if (count($live) > CACHE_MAX_ENTRIES) {
        usort($live, fn($a, $b) => filemtime($a) <=> filemtime($b));
        foreach (array_slice($live, 0, count($live) - CACHE_MAX_ENTRIES) as $file) {
            @unlink($file);
        }
    }
}

// ---------------------------------------------------------------------------
// Fetching
// ---------------------------------------------------------------------------

/**
 * Performs one GET against an already-validated URL.
 *
 * @return array{location: string}   when the upstream answers with a redirect
 * @return array{body: string, mime: string}  on success
 * Fails the request (and exits) for every other outcome.
 */
function fetch_once(string $url): array {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HEADER         => true,
        CURLOPT_FOLLOWLOCATION => false,   // handled manually so the guard re-runs
        CURLOPT_MAXREDIRS      => 0,
        CURLOPT_CONNECTTIMEOUT => TIMEOUT_SECONDS,
        CURLOPT_TIMEOUT        => TIMEOUT_SECONDS,
        CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; DotaHeroesApp/1.0; +image-proxy)',
        CURLOPT_ENCODING       => '',
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);

    // Enforce the size cap here so chunked responses without a Content-Length
    // are covered too, not just the ones that advertise their size.
    // Callback signature is ($ch, $download_size, $downloaded, $upload_size,
    // $uploaded) - the downloaded total is the third argument, not the fourth.
    $oversized = false;
    curl_setopt($ch, CURLOPT_NOPROGRESS, false);
    curl_setopt($ch, CURLOPT_PROGRESSFUNCTION, function ($ch, $downloadSize, $downloaded, $uploadSize, $uploaded) use (&$oversized) {
        if ($downloaded > MAX_BYTES) {
            $oversized = true;
            return 1;   // any non-zero return aborts the transfer
        }
        return 0;
    });

    $raw = curl_exec($ch);
    if ($oversized) {
        curl_close($ch);
        fail(413, "Image is larger than the 5 MB limit.");
    }
    if ($raw === false) {
        $error = curl_errno($ch);
        curl_close($ch);
        fail(502, "Could not reach the upstream server (cURL error $error).");
    }

    $status     = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    $headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $mime       = image_mime(curl_getinfo($ch, CURLINFO_CONTENT_TYPE) ?: null);
    curl_close($ch);

    $headers = substr($raw, 0, $headerSize);
    $body    = substr($raw, $headerSize);

    if ($status >= 300 && $status < 400) {
        if (preg_match('/^Location:\s*(.+)$/mi', $headers, $m) !== 1) {
            fail(502, "Upstream server returned a redirect without a destination.");
        }
        return ['location' => trim($m[1])];
    }

    if ($status !== 200) {
        fail(502, "Upstream server responded with status $status.");
    }
    if ($mime === null) {
        fail(415, "Upstream resource is not an image.");
    }
    if ($body === '' || $body === false) {
        fail(502, "Upstream server returned an empty response.");
    }

    return ['body' => $body, 'mime' => $mime];
}

/** Streams an image to the client and ends the request. */
function serve(string $mime, string $body, string $cacheState): void {
    // Override the JSON content type from cors.php with the real image type.
    header("Content-Type: $mime");
    header("Content-Length: " . strlen($body));
    header("Cache-Control: public, max-age=" . BROWSER_MAX_AGE);
    header("X-Image-Cache: $cacheState");
    http_response_code(200);
    echo $body;
    exit();
}

$requested = $_GET['url'] ?? '';
if (!is_string($requested) || trim($requested) === '') {
    fail(400, "Missing required 'url' parameter.");
}

// "1" forces a fresh fetch; anything else (or absent) allows a cached copy.
$refresh = ($_GET['refresh'] ?? '') === '1';

$current = trim($requested);

// Validated before the cache is consulted, so a URL that would be rejected can
// never be served from disk either.
assert_safe_url($current);

$file = cache_file($current);

if (!$refresh) {
    $hit = cache_read($file);
    if ($hit !== null) {
        serve($hit['mime'], $hit['body'], 'HIT');
    }
}

for ($hop = 0; $hop <= MAX_REDIRECTS; $hop++) {
    assert_safe_url($current);

    $result = fetch_once($current);

    if (isset($result['body'])) {
        cache_write($file, $result['mime'], $result['body']);
        cache_prune(dirname($file));
        serve($result['mime'], $result['body'], 'MISS');
    }

    // Resolved against the URL we just requested, then re-validated next hop.
    $current = resolve_location($current, $result['location']);
}

fail(502, "Too many redirects while fetching the image.");
