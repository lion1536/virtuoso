-- ============================================
-- VIRTUOSO - Music Streaming Platform
-- Database Schema
-- ============================================

-- Criar o banco de dados
CREATE DATABASE IF NOT EXISTS music;
USE music;

-- ============================================
-- Tabela de Usuários
-- ============================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    profile_picture VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    subscription_type ENUM('free', 'premium') DEFAULT 'free'
);

-- ============================================
-- Tabela de Gêneros Musicais
-- ============================================
CREATE TABLE genres (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Tabela de Artistas
-- ============================================
CREATE TABLE artists (
    artist_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    bio TEXT,
    profile_picture VARCHAR(255),
    country VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE
);

-- ============================================
-- Tabela de Álbuns
-- ============================================
CREATE TABLE albums (
    album_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    artist_id INT NOT NULL,
    cover_image VARCHAR(255),
    release_date DATE,
    genre_id INT,
    total_tracks INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE SET NULL
);

-- ============================================
-- Tabela de Músicas (Tracks)
-- ============================================
CREATE TABLE tracks (
    track_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    artist_id INT NOT NULL,
    album_id INT,
    genre_id INT,
    duration INT NOT NULL, -- duração em segundos
    file_path VARCHAR(255) NOT NULL, -- caminho do arquivo de áudio
    cover_image VARCHAR(255),
    release_date DATE,
    play_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE,
    FOREIGN KEY (album_id) REFERENCES albums(album_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE SET NULL
);

-- ============================================
-- Tabela de Playlists
-- ============================================
CREATE TABLE playlists (
    playlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    cover_image VARCHAR(255),
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================
-- Tabela de Músicas nas Playlists (Relacionamento N:N)
-- ============================================
CREATE TABLE playlist_tracks (
    playlist_track_id INT AUTO_INCREMENT PRIMARY KEY,
    playlist_id INT NOT NULL,
    track_id INT NOT NULL,
    position INT NOT NULL, -- ordem da música na playlist
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE CASCADE,
    UNIQUE KEY unique_playlist_track (playlist_id, track_id)
);

-- ============================================
-- Tabela de Favoritos dos Usuários
-- ============================================
CREATE TABLE user_favorites (
    favorite_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    track_id INT,
    album_id INT,
    artist_id INT,
    favorited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE CASCADE,
    FOREIGN KEY (album_id) REFERENCES albums(album_id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE,
    CHECK (
        (track_id IS NOT NULL AND album_id IS NULL AND artist_id IS NULL) OR
        (track_id IS NULL AND album_id IS NOT NULL AND artist_id IS NULL) OR
        (track_id IS NULL AND album_id IS NULL AND artist_id IS NOT NULL)
    )
);

-- ============================================
-- Tabela de Histórico de Reprodução
-- ============================================
CREATE TABLE play_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    track_id INT NOT NULL,
    played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed BOOLEAN DEFAULT FALSE, -- se ouviu a música completa
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE CASCADE
);

-- ============================================
-- Tabela de Seguidores (Follow System)
-- ============================================
CREATE TABLE user_follows (
    follow_id INT AUTO_INCREMENT PRIMARY KEY,
    follower_id INT NOT NULL, -- quem está seguindo
    followed_id INT NOT NULL, -- quem está sendo seguido
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (follower_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (followed_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_follow (follower_id, followed_id),
    CHECK (follower_id != followed_id)
);

-- ============================================
-- Índices para Melhorar Performance
-- ============================================
CREATE INDEX idx_tracks_artist ON tracks(artist_id);
CREATE INDEX idx_tracks_album ON tracks(album_id);
CREATE INDEX idx_tracks_genre ON tracks(genre_id);
CREATE INDEX idx_albums_artist ON albums(artist_id);
CREATE INDEX idx_playlists_user ON playlists(user_id);
CREATE INDEX idx_play_history_user ON play_history(user_id);
CREATE INDEX idx_play_history_track ON play_history(track_id);
CREATE INDEX idx_play_history_date ON play_history(played_at);