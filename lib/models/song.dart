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
    final authors = json['authors'] as List?;
    final authorName = authors != null && authors.isNotEmpty
        ? (authors[0] as Map<String, dynamic>)['author_name'] as String? ??
              '未知艺术家'
        : '未知艺术家';

    // 处理酷狗图片URL模板，将{size}替换为512
    String? coverArt = json['album_sizable_cover'] as String?;
    if (coverArt != null && coverArt.contains('{size}')) {
      coverArt = coverArt.replaceAll('{size}', '512');
    }

    return Song(
      id: json['audio_id']?.toString() ?? json['hash'] as String,
      title: json['songname'] as String,
      artist: authorName,
      album: json['album_name'] as String? ?? '未知专辑',
      coverArt: coverArt,
      url: '', // 将在获取播放URL时设置
      duration: json['timelength'] as int?,
      hash128: json['hash_128'] as String?,
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
