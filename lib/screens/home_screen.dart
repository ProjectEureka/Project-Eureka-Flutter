import 'package:flutter/material.dart';
import 'package:project_eureka_flutter/components/eureka_appbar.dart';
import 'package:project_eureka_flutter/components/eureka_list_view.dart';
import 'package:project_eureka_flutter/components/side_menu.dart';
import 'package:project_eureka_flutter/models/user_model.dart';
import 'package:project_eureka_flutter/screens/chat_screens/user_chats.dart';
import 'package:project_eureka_flutter/services/all_question_service.dart';
import 'package:project_eureka_flutter/services/email_auth.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //Made for testing purposes. Used to see if the Users Will Properly show on the home page
  UserModel user;
  String userId = EmailAuth().getCurrentUser().uid;

  // Questions data. Unfiltered list of questions
  List data = [];

  // Will filter the list of questions
  List questionsListFiltered = [];

  // These lists will help to filter questions by both search key and category simultaneously
  // Might be inefficient to use that many lists around, thus, this might change in the future versions to something more dynamic and efficient
  List questionsListFilteredCategory = [];
  List questionsListFilteredSearch = [];

  // isSearching keep track of whether search bar is activated or not. Search bar will appear if user clicked a search icon.
  bool isSearching = false;

  // Keeps track of the last chosen category. By default is All Categories.
  String selectedCategory = "All Categories";
  String dropdownValue = 'All Categories';

  ///
  ///for chat screen testing purposes
  String fromId = "hJGcQsILP7XQDSvWY2Qx2k3MD0V2";

  // Get data from the database to the list. Questions are shown on home page is always questionsListFiltered,
  // which at this point is a copy of a `data`, as no filters have been applied yet
  @override
  void initState() {
    initGetQuestions();
    super.initState();
  }

  Future<void> _getData() async {
    setState(() {
      selectedCategory = "All Categories";
      isSearching = false;
      initGetQuestions();
    });
  }

  void initGetQuestions() {
    AllQuestionService().getQuestions().then((payload) {
      setState(() {
        data = questionsListFiltered = questionsListFilteredSearch =
            questionsListFilteredCategory = payload;
      });
    });
  }

  // Called from widget (class) category filter
  void getCategory(value) {
    setState(() {
      filterQuestionsCategory(value);
    });
  }

  /// toggle searching on and off
  void toggleSearching() {
    setState(() {
      if (this.isSearching == true) {
        // Button to drop search bar. Will keep list filtered if category filter is applied
        questionsListFilteredSearch =
            data; // search list is now the same as the original
        filterQuestionsCategory(
            selectedCategory); // if "All Categories", then it page is completely unfiltered
        this.isSearching = false;
      } else if (this.isSearching == false) {
        this.isSearching = true;
      }
    });
  }

  // Called by search bar. Returns filtered list
  // Works with title and description (and category in case if user enters category in search bar)
  // In case if category filter is applied to the list of questions, search filter is applied to `questionsListFilteredCategory`,
  //    which might or might not have filter applied
  void filterQuestionsSearch(value) {
    setState(() {
      questionsListFiltered = questionsListFilteredSearch =
          questionsListFilteredCategory
              .where((question) =>
                  question.title.toLowerCase().contains(value.toLowerCase()) |
                          question.description
                              .toLowerCase()
                              .contains(value.toLowerCase()) |
                          question.category
                              .toLowerCase()
                              .contains(value.toLowerCase())
                      ? true
                      : false)
              .toList();
    });
  }

  // Category filter.
  // In case if search is applied to the list of questions, category filter is applied to `questionsListFilteredSearch`,
  //    which might or might not have filter applied
  void filterQuestionsCategory(value) {
    selectedCategory = value;
    if (value == "All Categories") {
      questionsListFiltered =
          questionsListFilteredCategory = questionsListFilteredSearch;
    } else {
      setState(() {
        questionsListFiltered = questionsListFilteredCategory =
            questionsListFilteredSearch
                .where((question) => question.category
                        .toLowerCase()
                        .contains(value.toLowerCase())
                    ? true
                    : false)
                .toList();
      });
    }
  }

  Visibility _noResults(int filteredQuestionListLength, int dataLength) {
    // if data list length is 0, it means the data is still loading from backend services - show loading circle
    // if filtered data list is empty, but data list is not, it means that there is no result based on search and/or category - "no results"
    if (data.length == 0) {
      return Visibility(
        visible: filteredQuestionListLength == 0.0,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return Visibility(
        visible: filteredQuestionListLength == 0.0,
        child: Center(
          child: Text(
            "No results",
          ),
        ),
      );
    }
  }

  EurekaAppBar homeAppBar() {
    return EurekaAppBar(
      title: !isSearching
          ? Container(
              child: Image.asset('assets/images/EureQaLogo.png', width: 140),
            )
          : TextField(
              onChanged: (value) {
                // Call function to apply search filter
                filterQuestionsSearch(value);
              },
              style: TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                icon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                hintText: "Search Question",
                hintStyle: TextStyle(color: Colors.white),
              ),
            ),
      appBar: AppBar(),
      actions: [
        isSearching
            ? IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  toggleSearching();
                },
              )
            : IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  toggleSearching();
                },
              ),

        // Chat button
        FlatButton(
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreenConversations(),
              ),
            );
          }, // redirect to Chat page
          child: Icon(Icons.chat_sharp, color: Color(0xFF00ADB5)),
          shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
        ),
      ],
    );
  }

  DropdownButton _buildCategoryFilter(/* _callback */) {
    return DropdownButton<String>(
      value: selectedCategory,
      icon: Icon(Icons.menu),
      iconSize: 25.0,
      elevation: 16,
      underline: Container(
        height: 2.0,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String newValue) {
        // Call function in Home class
        getCategory(newValue);
        setState(() {
          selectedCategory = newValue;
          print(selectedCategory);
        });
      },
      items: <String>[
        'All Categories',
        'Technology',
        'Household',
        'Lifestyle',
        'Academic'
      ].map<DropdownMenuItem<String>>(
        (String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value,
                style: TextStyle(fontSize: 15.0, color: Colors.purple)),
          );
        },
      ).toList(),
    );
  }

  Row _categoryFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 15.0,
          ),
          child: _buildCategoryFilter(),
        )
      ],
    );
  }

  Column questionsList() {
    return Column(
      children: [
        // List of Questions
        Expanded(
          // Show loading circle if results are taking time
          // Show "No results" if input text doesn't match with question title (later will be added to description too)
          child: RefreshIndicator(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: questionsListFiltered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // category filter are above the first row. If there is no questions to show, it will still be there.
                  return Column(
                    children: <Widget>[
                      _categoryFilter(),
                      _noResults(questionsListFiltered.length, data.length),
                    ],
                  );
                }
                index -= 1;
                return EurekaListView(
                  questionList: questionsListFiltered,
                  index: index,
                );
              },
            ),
            // Once list is pulled down, onRefresh will call _getDate that will call all_question_service to update data on the screen
            // Does not work when category or search bar are in use
            onRefresh: _getData,
          ),
        ),
      ],
    );
  }

  Container _createNewQuestionButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: FlatButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/newQuestion');
        },
        color: Color(0xFF00ADB5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Container(
            child: Text(
              "Create New Question",
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // *** WIDGET BUILD ***
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      resizeToAvoidBottomInset: false,
      // fixed: "Create New Question" button was moving up while in keyboard mode
      appBar: homeAppBar(),

      // List of questions and a category filter
      // Call function questionsList
      body: questionsList(),

      bottomNavigationBar: _createNewQuestionButton(),
    );
  }
}
