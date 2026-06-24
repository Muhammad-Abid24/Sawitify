class ConcertModel {
  final String title;

  final String? startDate;

  final String? eventDate;

  final int? eventYear;

  final String? when;

  final List<String> address;

  final String? description;

  final String? link;

  final String? mapImage;

  final String? mapLink;

  final String? thumnail;

  final String? image;

  final List<TicketInfo> tickets;

  ConcertModel({
    required this.title,

    this.startDate,

    this.eventDate,

    this.eventYear,

    this.when,

    required this.address,

    this.description,

    this.link,

    this.mapImage,

    this.mapLink,

    this.thumnail,

    this.image,

    required this.tickets,
  });

  factory ConcertModel.fromJson(Map<String, dynamic> json) {
    return ConcertModel(
      title: json['title'] ?? '',

      startDate: json['startDate'],

      eventDate: json['eventDate'],

      eventYear: json['eventYear'],

      when: json['when'],

      address: List<String>.from(json['address'] ?? []),

      description: json['description'],

      link: json['link'],

      mapImage: json['mapImage'],

      mapLink: json['mapLink'],

      thumnail: json['thumbnail'],

      image: json['image'],

      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((e) => TicketInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class TicketInfo {
  final String source;

  final String? sourceIcon;

  final String? link;

  final String? linkType;

  TicketInfo({required this.source, this.sourceIcon, this.link, this.linkType});

  factory TicketInfo.fromJson(Map<String, dynamic> json) {
    return TicketInfo(
      source: json['source'] ?? '',

      sourceIcon: json['source_icon'],

      link: json['link'],

      linkType: json['link_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,

      'source_icon': sourceIcon,

      'link': link,

      'link_type': linkType,
    };
  }
}
