import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../checkit/HomePage.dart';
import '../../checkit/home.dart';
import '../../checkit/providerF.dart';
import '../tests/HomeScreenv3.dart';
import '../tests/hotelScreen.dart';
import '../tests/timelines/HotelRoomTimelineScreen.dart' as t;
import '../tests/timelines/Tinder-clone-main/Tinder-clone-main/lib/main.dart';
import '../tests/timelines/mistral/claude.dart';
import '../tests/timelines/mistral/mistralAncien.dart';


class MyApp_image_picker extends StatelessWidget {
  const MyApp_image_picker({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Image Picker Demo',
      home: MyHomePage(title: 'Image Picker Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<XFile>? _mediaFileList;

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController limitController = TextEditingController();

  Future<void> _playVideo(XFile? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      late VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }
      _controller = controller;
      // In web, most browsers won't honor a programmatic call to .play
      // if the video has a sound track (and is not muted).
      // Mute the video so it auto-plays in web!
      // This is not needed if the call to .play is the result of user
      // interaction (clicking on a "play" button, for example).
      const double volume = kIsWeb ? 0.0 : 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    }
  }

  Future<void> _onImageButtonPressed(ImageSource source, {
    required BuildContext context,
    bool isMultiImage = false,
    bool isMedia = false,
  }) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    if (context.mounted) {
      if (isVideo) {
        final XFile? file = await _picker.pickVideo(
            source: source, maxDuration: const Duration(seconds: 10));
        await _playVideo(file);
      } else if (isMultiImage) {
        await _displayPickImageDialog(context, true, (double? maxWidth,
            double? maxHeight, int? quality, int? limit) async {
          try {
            final List<XFile> pickedFileList = isMedia
                ? await _picker.pickMultipleMedia(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              imageQuality: quality,
              limit: limit,
            )
                : await _picker.pickMultiImage(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              imageQuality: quality,
              limit: limit,
            );
            setState(() {
              _mediaFileList = pickedFileList;
            });
          } catch (e) {
            setState(() {
              _pickImageError = e;
            });
          }
        });
      } else if (isMedia) {
        await _displayPickImageDialog(context, false, (double? maxWidth,
            double? maxHeight, int? quality, int? limit) async {
          try {
            final List<XFile> pickedFileList = <XFile>[];
            final XFile? media = await _picker.pickMedia(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              imageQuality: quality,
            );
            if (media != null) {
              pickedFileList.add(media);
              setState(() {
                _mediaFileList = pickedFileList;
              });
            }
          } catch (e) {
            setState(() {
              _pickImageError = e;
            });
          }
        });
      } else {
        await _displayPickImageDialog(context, false, (double? maxWidth,
            double? maxHeight, int? quality, int? limit) async {
          try {
            final XFile? pickedFile = await _picker.pickImage(
              source: source,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              imageQuality: quality,
            );
            setState(() {
              _setImageFileListFromFile(pickedFile);
            });
          } catch (e) {
            setState(() {
              _pickImageError = e;
            });
          }
        });
      }
    }
  }

  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeVideoController();
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }

  Widget _previewVideo() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_controller == null) {
      return const Text(
        'You have not yet picked a video',
        textAlign: TextAlign.center,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AspectRatioVideo(_controller),
    );
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return Semantics(
        label: 'image_picker_example_picked_images',
        child: ListView.builder(
          key: UniqueKey(),
          itemBuilder: (BuildContext context, int index) {
            final String? mime = lookupMimeType(_mediaFileList![index].path);

            // Why network for web?
            // See https://pub.dev/packages/image_picker_for_web#limitations-on-the-web-platform
            return Semantics(
              label: 'image_picker_example_picked_image',
              child: kIsWeb
                  ? Image.network(_mediaFileList![index].path)
                  : (mime == null || mime.startsWith('image/')
                  ? Image.file(
                File(_mediaFileList![index].path),
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return const Center(
                      child:
                      Text('This image type is not supported'));
                },
              )
                  : _buildInlineVideoPlayer(index)),
            );
          },
          itemCount: _mediaFileList!.length,
        ),
      );
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildInlineVideoPlayer(int index) {
    final VideoPlayerController controller =
    VideoPlayerController.file(File(_mediaFileList![index].path));
    const double volume = kIsWeb ? 0.0 : 1.0;
    controller.setVolume(volume);
    controller.initialize();
    controller.setLooping(true);
    controller.play();
    return Center(child: AspectRatioVideo(controller));
  }

  Widget _handlePreview() {
    if (isVideo) {
      return _previewVideo();
    } else {
      return _previewImages();
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.video) {
        isVideo = true;
        await _playVideo(response.file);
      } else {
        isVideo = false;
        setState(() {
          if (response.files == null) {
            _setImageFileListFromFile(response.file);
          } else {
            _mediaFileList = response.files;
          }
        });
      }
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
          future: retrieveLostData(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const Text(
                  'You have not yet picked an image.',
                  textAlign: TextAlign.center,
                );
              case ConnectionState.done:
                return _handlePreview();
              case ConnectionState.active:
                if (snapshot.hasError) {
                  return Text(
                    'Pick image/video error: ${snapshot.error}}',
                    textAlign: TextAlign.center,
                  );
                } else {
                  return const Text(
                    'You have not yet picked an image.',
                    textAlign: TextAlign.center,
                  );
                }
            }
          },
        )
            : _handlePreview(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Semantics(
            label: 'image_picker_example_from_gallery',
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.gallery, context: context);
              },
              heroTag: 'image0',
              tooltip: 'Pick Image from gallery',
              child: const Icon(Icons.photo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                  isMultiImage: true,
                  isMedia: true,
                );
              },
              heroTag: 'multipleMedia',
              tooltip: 'Pick Multiple Media from gallery',
              child: const Icon(Icons.photo_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                  isMedia: true,
                );
              },
              heroTag: 'media',
              tooltip: 'Pick Single Media from gallery',
              child: const Icon(Icons.photo_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                  isMultiImage: true,
                );
              },
              heroTag: 'image1',
              tooltip: 'Pick Multiple Image from gallery',
              child: const Icon(Icons.photo_library),
            ),
          ),
          if (_picker.supportsImageSource(ImageSource.camera))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: FloatingActionButton(
                onPressed: () {
                  isVideo = false;
                  _onImageButtonPressed(ImageSource.camera, context: context);
                },
                heroTag: 'image2',
                tooltip: 'Take a Photo',
                child: const Icon(Icons.camera_alt),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.gallery, context: context);
              },
              heroTag: 'video0',
              tooltip: 'Pick Video from gallery',
              child: const Icon(Icons.video_library),
            ),
          ),
          if (_picker.supportsImageSource(ImageSource.camera))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  isVideo = true;
                  _onImageButtonPressed(ImageSource.camera, context: context);
                },
                heroTag: 'video1',
                tooltip: 'Take a Video',
                child: const Icon(Icons.videocam),
              ),
            ),
        ],
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Future<void> _displayPickImageDialog(BuildContext context, bool isMulti,
      OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add optional parameters'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: maxWidthController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'Enter maxWidth if desired'),
                ),
                TextField(
                  controller: maxHeightController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'Enter maxHeight if desired'),
                ),
                TextField(
                  controller: qualityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Enter quality if desired'),
                ),
                if (isMulti)
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: 'Enter limit if desired'),
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    final double? width = maxWidthController.text.isNotEmpty
                        ? double.parse(maxWidthController.text)
                        : null;
                    final double? height = maxHeightController.text.isNotEmpty
                        ? double.parse(maxHeightController.text)
                        : null;
                    final int? quality = qualityController.text.isNotEmpty
                        ? int.parse(qualityController.text)
                        : null;
                    final int? limit = limitController.text.isNotEmpty
                        ? int.parse(limitController.text)
                        : null;
                    onPick(width, height, quality, limit);
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}

typedef OnPickImageCallback = void Function(
    double? maxWidth, double? maxHeight, int? quality, int? limit);

class AspectRatioVideo extends StatefulWidget {
  const AspectRatioVideo(this.controller, {super.key});

  final VideoPlayerController? controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController? get controller => widget.controller;
  bool initialized = false;

  void _onVideoControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (initialized != controller!.value.isInitialized) {
      initialized = controller!.value.isInitialized;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    controller!.addListener(_onVideoControllerUpdate);
  }

  @override
  void dispose() {
    controller!.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      );
    } else {
      return Container();
    }
  }
}

class ReservationNavigationButtons extends StatelessWidget {
  final List<String> roomNumbers;

  const ReservationNavigationButtons({Key? key, required this.roomNumbers})
      : super(key: key);

  List<Reservation> get sampleReservations =>
      [
        Reservation(
          clientName: "John Doe",
          roomName: "101",
          startDate: DateTime(2025, 1, 5),
          endDate: DateTime(2025, 1, 9),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "102",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "103",
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "104",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "105",
          startDate: DateTime(2025, 1, 2),
          endDate: DateTime(2025, 1, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "108",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "101",
          startDate: DateTime(2025, 1, 5),
          endDate: DateTime(2025, 1, 9),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "102",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "103",
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "104",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "105",
          startDate: DateTime(2025, 1, 2),
          endDate: DateTime(2025, 1, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "108",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "101",
          startDate: DateTime(2025, 1, 5),
          endDate: DateTime(2025, 1, 9),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "102",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "103",
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "104",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "105",
          startDate: DateTime(2025, 1, 2),
          endDate: DateTime(2025, 1, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "108",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "101",
          startDate: DateTime(2025, 1, 5),
          endDate: DateTime(2025, 1, 9),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "102",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "103",
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "104",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "105",
          startDate: DateTime(2025, 1, 2),
          endDate: DateTime(2025, 1, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "108",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "101",
          startDate: DateTime(2025, 1, 5),
          endDate: DateTime(2025, 1, 9),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "102",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "103",
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "104",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
        Reservation(
          clientName: "John Doe",
          roomName: "105",
          startDate: DateTime(2025, 1, 2),
          endDate: DateTime(2025, 1, 5),
          pricePerNight: 100.0,
          status: "Confirmed",
        ),
        Reservation(
          clientName: "Jane Smith",
          roomName: "108",
          startDate: DateTime(2025, 2, 4),
          endDate: DateTime(2025, 2, 5),
          pricePerNight: 150.0,
          status: "Checked In",
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 58.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) =>
                          HotelReservationChart(
                            fromDate: DateTime(2025, 1, 1),
                            toDate: DateTime(2025, 12, 31),
                            roomNames: roomNumbers,
                            reservations: sampleReservations,
                          ),
                    ));
                  },
                  child: Text('Hotel'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed))
                        return Colors.yellow;
                      return Colors.deepPurple;
                    }),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    overlayColor: WidgetStateProperty.all(Colors.black12),
                    shadowColor: WidgetStateProperty.all(Colors.black),
                    surfaceTintColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(6.0),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    minimumSize: WidgetStateProperty.all(Size(100, 40)),
                    fixedSize: WidgetStateProperty.all(Size(150, 50)),
                    maximumSize: WidgetStateProperty.all(Size(200, 60)),
                    iconColor: WidgetStateProperty.all(Colors.yellow),
                    iconSize: WidgetStateProperty.all(24.0),
                    iconAlignment: IconAlignment.start,
                    // side: WidgetStateProperty.all(
                    //   BorderSide(color: Colors.red, width: 2),
                    // ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    mouseCursor:
                    WidgetStateProperty.all(SystemMouseCursors.click),
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    animationDuration: Duration(milliseconds: 300),
                    enableFeedback: true,
                    alignment: Alignment.center,
                    splashFactory: InkRipple.splashFactory,
                    // backgroundBuilder: (context, states, child) {
                    //   return Container(
                    //     decoration: BoxDecoration(
                    //       gradient: LinearGradient(
                    //         colors: [Colors.blue, Colors.purple],
                    //       ),
                    //     ),
                    //     child: child,
                    //   );
                    // },
                    foregroundBuilder: (context, states, child) {
                      return Icon(Icons.star, color: Colors.white);
                    },
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => HomeScreenv3()));
                  },
                  child: Text('Hotel V3'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.blue),
                    foregroundColor:
                    WidgetStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => MyApp_TinderClone()));
                  },
                  child: Text('Tinder Clone'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) =>
                          CalendarTableWithDragging(
                            fromDate: DateTime.now(),
                            toDate: DateTime.now().add(Duration(days: 30)),
                            // roomNames: roomNumbers,
                            roomNames:
                            List.generate(30, (index) => 'Room ${index + 1}'),
                            reservations: sampleReservations,
                          ),
                    ));
                  },
                  child: Text('Hotel Fiable'),
                ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.blue),
                    foregroundColor:
                    WidgetStateProperty.all<Color>(Colors.yellowAccent),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => t.HotelRoomTimelineScreen()));
                  },
                  child: Text('HotelRoomTimelineScreen'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.blue),
                    foregroundColor:
                    WidgetStateProperty.all<Color>(Colors.yellowAccent),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => t.HotelRoomTimelineInfiniteScreen()));
                  },
                  child: Text('HotelRoomTimelineInfiniteScreen'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.blue),
                    foregroundColor:
                    WidgetStateProperty.all<Color>(Colors.yellowAccent),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => t.HotelRoomTimelineScreen2()));
                  },
                  child: Text('HotelRoomTimelineScreen2'),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.blue),
                        foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.yellowAccent),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => Hotel_ManagementA()));
                      },
                      child: Text('Hotel_ManagementA'),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.blue),
                        foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.yellowAccent),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => Hotel_Management()));
                      },
                      child: Text('Hotel_Management'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => SignalHomePage_Firebase(),
                    ));
                  },
                  child: Text('Sheckit Firebase'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => HomePage3(),
                    ));
                  },
                  child: Text('HomePage3'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final GlobalKey<FormFieldState>? fieldKey;
  final bool resetOnClear;
  final bool isNumberPhone;
  final VoidCallback? onTextCleared;

  AnimatedTextField({
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.fieldKey,
    this.resetOnClear = false,
    required this.isNumberPhone,
    this.onTextCleared,
  });

  @override
  _AnimatedTextFieldState createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    // Ajout du listener en référence à une méthode correctement définie.
    widget.controller.addListener(_onControllerChanged);
  }

  // Méthode pour gérer les changements du controller
  void _onControllerChanged() {
    // Si le texte est vide et que l'icône est validée, on réinitialise _isValid.
    if (widget.controller.text.isEmpty && _isValid) {
      setState(() {
        _isValid = false;
      });
      // Appeler le callback si le texte est vide
      if (widget.onTextCleared != null) {
        widget.onTextCleared!();
      }
    }
  }

  @override
  void dispose() {
    // Retirer le listener pour éviter d'éventuels appels sur un state déjà détruit.
    widget.controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _validatePhoneNumber(String value) {
    final provider =
    Provider.of<SignalementProviderSupabase>(context, listen: false);
    setState(() {
      if (value.isEmpty) {
        _isValid = false;
      } else {
        _isValid = provider.isValidAlgerianPhoneNumber(value);
      }
    });
  }

  // void resetIcon() {
  //   if (widget.resetOnClear) {
  //     setState(() {
  //       _isValid = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            key: widget.fieldKey,
            controller: widget.controller,
            decoration: widget.isNumberPhone
                ? InputDecoration(
              labelText: widget.labelText,
              prefixIcon: widget.controller.text.isNotEmpty
                  ? _isValid
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.error, color: Colors.red)
                  : null,
              suffixIcon: widget.controller.text.isNotEmpty
                  ? Transform.scale(
                scale: 0.7,
                child: IconButton(
                  icon: Icon(Icons.close),
                  color: Colors.red,
                  onPressed: () {
                    FocusScope.of(context)
                        .unfocus(); // Enlève le fo
                    setState(() {
                      widget.controller.clear();
                    });
                    if (widget.onTextCleared != null) {
                      widget.onTextCleared!();
                    }
                  },
                ),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: EdgeInsets.all(8),
            )
                : InputDecoration(
              labelText: widget.labelText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: EdgeInsets.all(8),
            ),
            style: TextStyle(
              fontSize: 25, // Agrandir le texte ici
            ),
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: _validatePhoneNumber,
            textAlign: TextAlign.center,
          ),
        ));
  }
}

class AnimatedLongTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final GlobalKey<FormFieldState>? fieldKey;
  final bool resetOnClear;
  final bool isNumberPhone;

  AnimatedLongTextField({
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.fieldKey,
    this.resetOnClear = false,
    required this.isNumberPhone,
  });

  @override
  _AnimatedLongTextFieldState createState() => _AnimatedLongTextFieldState();
}

class _AnimatedLongTextFieldState extends State<AnimatedLongTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    // Ajout du listener en référence à une méthode correctement définie.
    widget.controller.addListener(_onControllerChanged);
  }

  // Méthode pour gérer les changements du controller
  void _onControllerChanged() {
    // Si le texte est vide et que l'icône est validée, on réinitialise _isValid.
    if (widget.controller.text.isEmpty && _isValid) {
      setState(() {
        _isValid = false;
      });
    }
  }

  @override
  void dispose() {
    // Retirer le listener pour éviter d'éventuels appels sur un state déjà détruit.
    widget.controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _validatePhoneNumber(String value) {
    final provider =
    Provider.of<SignalementProviderSupabase>(context, listen: false);
    setState(() {
      if (value.isEmpty) {
        _isValid = false;
      } else {
        _isValid = provider.isValidAlgerianPhoneNumber(value);
      }
    });
  }

  void resetIcon() {
    if (widget.resetOnClear) {
      setState(() {
        _isValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: TextFormField(
        key: widget.fieldKey,
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          alignLabelWithHint: true,
          hintText: 'Entrez un texte long ici...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: EdgeInsets.all(15),
        ),
        textInputAction: TextInputAction.newline,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        onChanged: _validatePhoneNumber,
        textAlign: TextAlign.start,
        keyboardType: TextInputType.multiline,
        maxLines: 5,
        // permet une hauteur dynamique selon le contenu
        minLines: 5,
        // pour afficher directement plusieurs lignes
        expands:
        false, // false pour ne pas forcer à remplir tout l'espace parent
      ),
    );
  }
}
