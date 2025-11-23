class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? coverArt;
  final String url;
  final int? duration;
  final bool isLocal;
  final String? hash128;
  final String? hash320;
  final String? hashHigh;
  final String? hashFlac;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.coverArt,
    required this.url,
    this.duration,
    this.isLocal = false,
    this.hash128,
    this.hash320,
    this.hashHigh,
    this.hashFlac,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      coverArt: json['coverArt'] as String?,
      url: json['url'] as String,
      duration: json['duration'] as int?,
      isLocal: json['isLocal'] as bool? ?? false,
      hash128: json['hash128'] as String?,
      hash320: json['hash320'] as String?,
      hashHigh: json['hashHigh'] as String?,
      hashFlac: json['hashFlac'] as String?,
    );
  }

  // 从酷狗API数据创建Song对象
  factory Song.fromKugouJson(Map<String, dynamic> json) {
    // 处理艺术家名称 - 支持多种格式
    String artistName;
    if (json.containsKey('SingerName') && json['SingerName'] != null) {
      // 搜索API格式
      artistName = json['SingerName'] as String;
    } else if (json.containsKey('authors') && json['authors'] is List) {
      // 其他API格式
      final authors = json['authors'] as List;
      artistName = authors.isNotEmpty
          ? (authors[0] as Map<String, dynamic>)['author_name'] as String? ??
                '未知艺术家'
          : '未知艺术家';
    } else {
      artistName = '未知艺术家';
    }

    // 处理歌曲名称 - 支持多种格式
    String songName;
    if (json.containsKey('FileName') && json['FileName'] != null) {
      // 搜索API格式
      songName = json['FileName'] as String;
    } else if (json.containsKey('songname') && json['songname'] != null) {
      // 其他API格式
      songName = json['songname'] as String;
    } else if (json.containsKey('OriSongName') && json['OriSongName'] != null) {
      // 备选字段
      songName = json['OriSongName'] as String;
    } else {
      songName = '未知歌曲';
    }

    // 处理专辑名称
    String albumName;
    if (json.containsKey('AlbumName') && json['AlbumName'] != null) {
      albumName = json['AlbumName'] as String;
    } else if (json.containsKey('album_name') && json['album_name'] != null) {
      albumName = json['album_name'] as String;
    } else {
      albumName = '未知专辑';
    }

    // 处理封面图片URL - 支持多种格式
    String? coverArt;
    if (json.containsKey('Image') && json['Image'] != null) {
      // 搜索API格式
      coverArt = json['Image'] as String;
      if (coverArt.contains('{size}')) {
        coverArt = coverArt.replaceAll('{size}', '512');
      }
    } else if (json.containsKey('album_sizable_cover') &&
        json['album_sizable_cover'] != null) {
      // 其他API格式
      coverArt = json['album_sizable_cover'] as String;
      if (coverArt.contains('{size}')) {
        coverArt = coverArt.replaceAll('{size}', '512');
      }
    }

    // 处理ID和Hash
    String songId;
    if (json.containsKey('FileHash') && json['FileHash'] != null) {
      songId = json['FileHash'] as String;
    } else if (json.containsKey('Hash') && json['Hash'] != null) {
      songId = json['Hash'] as String;
    } else if (json.containsKey('audio_id') && json['audio_id'] != null) {
      songId = json['audio_id'].toString();
    } else if (json.containsKey('hash') && json['hash'] != null) {
      songId = json['hash'] as String;
    } else {
      songId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    return Song(
      id: songId,
      title: songName,
      artist: artistName,
      album: albumName,
      coverArt: coverArt,
      url: '', // 将在获取播放URL时设置
      duration: (json['Duration'] ?? json['timelength']) as int?,
      hash128: (json['FileHash'] ?? json['hash_128']) as String?,
      hash320: json['hash_320'] as String?,
      hashHigh: json['hash_high'] as String?,
      hashFlac: json['hash_flac'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'coverArt': coverArt,
      'url': url,
      'duration': duration,
      'isLocal': isLocal,
      'hash128': hash128,
      'hash320': hash320,
      'hashHigh': hashHigh,
      'hashFlac': hashFlac,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? coverArt,
    String? url,
    int? duration,
    bool? isLocal,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverArt: coverArt ?? this.coverArt,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Song{id: $id, title: $title, artist: $artist, album: $album}';
  }
}
