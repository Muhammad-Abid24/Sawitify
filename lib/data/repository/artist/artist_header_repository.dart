part of 'artist_repository.dart';

extension ArtistHeaderRepository on ArtistRepository {
  ArtistHeader _parseHeader(Map<String, dynamic> json, String browseId) {
    final header =
        json["header"]?["musicImmersiveHeaderRenderer"]
            as Map<String, dynamic>? ??
        {};

    //--------------------------------------------------
    // NAME
    //--------------------------------------------------

    final String name = _joinRuns(header["title"]?["runs"] as List?);

    //--------------------------------------------------
    // DESCRIPTION
    //--------------------------------------------------

    final String description = _joinRuns(
      header["description"]?["runs"] as List?,
    );

    //--------------------------------------------------
    // SUBSCRIBERS
    //--------------------------------------------------

    String subscribers = "";

    final subscriberRuns =
        header["subscriptionButton"]?["subscribeButtonRenderer"]?["subscriberCountText"]?["runs"]
            as List?;

    if (subscriberRuns != null && subscriberRuns.isNotEmpty) {
      subscribers = _joinRuns(subscriberRuns);
    }

    //--------------------------------------------------
    // MONTHLY LISTENERS
    //--------------------------------------------------

    String monthlyListeners = "";

    final monthlyRuns = header["monthlyListenerCount"]?["runs"] as List?;

    if (monthlyRuns != null && monthlyRuns.isNotEmpty) {
      monthlyListeners = _joinRuns(monthlyRuns);
    }

    //--------------------------------------------------
    // THUMBNAIL
    //--------------------------------------------------

    final String thumbnail = _thumbnail(header["thumbnail"]);

    //--------------------------------------------------
    // RESULT
    //--------------------------------------------------

    return ArtistHeader(
      browseId: browseId,
      name: name,
      description: description,
      subscribers: subscribers,
      monthlyListeners: monthlyListeners,
      thumbnail: thumbnail,
    );
  }
}
