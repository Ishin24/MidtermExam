-- ============================================================
-- Dota Heroes Database
-- Import this file in phpMyAdmin / MySQL to create the schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS dota_heroes_db CHARACTER SET utf8mb4;
USE dota_heroes_db;

CREATE TABLE IF NOT EXISTS heroes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    localized_name VARCHAR(100) NOT NULL,
    primary_attr ENUM('Strength', 'Agility', 'Intelligence', 'Universal') NOT NULL,
    attack_type ENUM('Melee', 'Ranged') NOT NULL,
    roles VARCHAR(255) DEFAULT '',
    img_url VARCHAR(500) DEFAULT '',
    lore TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Seed data: a handful of real Dota 2 heroes so the app has content immediately
INSERT INTO heroes (name, localized_name, primary_attr, attack_type, roles, img_url, lore) VALUES
('antimage', 'Anti-Mage', 'Agility', 'Melee', 'Carry, Escape, Nuker',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/antimage.png',
 'A mana-burning blade master who punishes reliance on magic.'),
('axe', 'Axe', 'Strength', 'Melee', 'Initiator, Durable, Disabler',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/axe.png',
 'A relentless warrior who dives into the fray and calls foes to their doom.'),
('crystal_maiden', 'Crystal Maiden', 'Intelligence', 'Ranged', 'Support, Disabler, Nuker',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/crystal_maiden.png',
 'A frost sorceress whose aura keeps her allies casting spells endlessly.'),
('pudge', 'Pudge', 'Strength', 'Melee', 'Disabler, Initiator, Durable',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/pudge.png',
 'A rotting butcher who hooks enemies from a distance and feasts on their flesh.'),
('invoker', 'Invoker', 'Intelligence', 'Ranged', 'Carry, Nuker, Disabler, Escape',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/invoker.png',
 'A master of the arcane arts who invokes combinations of ten elemental orbs.'),
('phantom_assassin', 'Phantom Assassin', 'Agility', 'Melee', 'Carry, Escape',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/phantom_assassin.png',
 'A blur of blades whose critical strikes end fights in an instant.'),
('shadow_fiend', 'Shadow Fiend', 'Agility', 'Ranged', 'Carry, Nuker',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/nevermore.png',
 'A demon who hurls the captured souls of his victims at his enemies.'),
('wraith_king', 'Wraith King', 'Strength', 'Melee', 'Carry, Durable, Disabler, Initiator',
 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/skeleton_king.png',
 'An undying monarch who returns from death itself to finish the fight.');
