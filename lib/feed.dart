import 'package:Fluttergram/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'image_post.dart';
import 'dart:async';
import 'main.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Feed extends StatefulWidget {
  _Feed createState() => _Feed();
}

class _Feed extends State<Feed> with AutomaticKeepAliveClientMixin<Feed> {
  List<ImagePost> feedData;

  @override
  void initState() {
    super.initState();
    this._loadFeed();
  }

  buildFeed() {
    if (feedData != null) {
      return ListView(
        children: feedData,
      );
    } else {
      return Container(
          alignment: FractionalOffset.center,
          child: CircularProgressIndicator());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // reloads state when opened again

    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        backgroundColor: Colors.yellowAccent,
        //brightness: Brightness.light,
        title: Row(
          children: <Widget>[
            //SizedBox(width: 12.0),
            GestureDetector(
              child: Text(
                'Social Market',
                style: TextStyle(
                    fontFamily: 'Zombie', color: Colors.black, fontSize: 25.0),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(OMIcons.liveTv),
            color: Colors.black,
            onPressed: () => showSnackbar(context, 'Live Promotions'),
          ),
          IconButton(
            icon: Icon(OMIcons.settings),
            color: Colors.black,
            onPressed: () => showSnackbar(context, 'Settings'),
            //onPressed: () {Navigator.of(context).push(CupertinoPageRoute(builder: (context) => DirectPage()));}
          )
        ],
        //<Widget>[
        //Builder(builder: (BuildContext context) {
        //return IconButton(
        //color: Colors.black,
        //icon: Icon(OMIcons.liveTv),
        //onPressed: () => showSnackbar(context, 'Live Promotions'),
        // );
        // }),
        //Builder(builder: (BuildContext context) {
        //  return IconButton(
        //    color: Colors.black,
        //    icon: Icon(OMIcons.settings),
        //    onPressed: () => showSnackbar(context, 'Settings'),
        //  );
        // }),
        // ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: buildFeed(),
      ),
    );
  }

  Future<Null> _refresh() async {
    await _getFeed();

    setState(() {});

    return;
  }

  _loadFeed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String json = prefs.getString("feed");

    if (json != null) {
      List<Map<String, dynamic>> data =
          jsonDecode(json).cast<Map<String, dynamic>>();
      List<ImagePost> listOfPosts = _generateFeed(data);
      setState(() {
        feedData = listOfPosts;
      });
    } else {
      _getFeed();
    }
  }

  _getFeed() async {
    print("Staring getFeed");

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userId = googleSignIn.currentUser.id.toString();
    var url =
        'https://us-central1-fluttergram-2c1da.cloudfunctions.net/getFeed?uid=' +
            userId;
    var httpClient = HttpClient();

    List<ImagePost> listOfPosts;
    String result;
    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        prefs.setString("feed", json);
        List<Map<String, dynamic>> data =
            jsonDecode(json).cast<Map<String, dynamic>>();
        listOfPosts = _generateFeed(data);
        result = "Success in http request for feed";
      } else {
        result =
            'Error getting a feed: Http status ${response.statusCode} | userId $userId';
      }
    } catch (exception) {
      result = 'Failed invoking the getFeed function. Exception: $exception';
    }
    print(result);

    setState(() {
      feedData = listOfPosts;
    });
  }

  List<ImagePost> _generateFeed(List<Map<String, dynamic>> feedData) {
    List<ImagePost> listOfPosts = [];

    for (var postData in feedData) {
      listOfPosts.add(ImagePost.fromJSON(postData));
    }

    return listOfPosts;
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;
}
