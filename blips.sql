CREATE TABLE IF NOT EXISTS `txgls_blips` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `sprite` int(11) NOT NULL DEFAULT 1,
    `color` int(11) NOT NULL DEFAULT 1,
    `x` decimal(10,2) NOT NULL,
    `y` decimal(10,2) NOT NULL,
    `z` decimal(10,2) NOT NULL,
    `created_by` varchar(100) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_name` (`name`),
    KEY `idx_coordinates` (`x`, `y`, `z`),
    KEY `idx_sprite_color` (`sprite`, `color`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
