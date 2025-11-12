import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverArt;
  final List<Song> songs;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverArt,
    required this.songs,
    required this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverArt: json['coverArt'] as String?,
      songs: (json['songs'] as List<dynamic>)
          .map((song) => Song.fromJson(song as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverArt': coverArt,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverArt,
    List<Song>? songs,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverArt: coverArt ?? this.coverArt,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get duration {
    if (songs.isEmpty) return 0;
    return songs
        .map((song) => song.duration ?? 0)
        .reduce((value, element) => value + element);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Playlist{id: $id, name: $name, songs: ${songs.length}}';
  }
}