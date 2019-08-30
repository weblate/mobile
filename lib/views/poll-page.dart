import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/constants/colors.dart';

class PollPageArgs {
  Ent ent;
  ProcessMetadata process;

  PollPageArgs({this.ent, this.process});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  List<String> responses = [];
  String responsesStateMessage = '';
  bool responsesAreValid = false;

  @override
  void didChangeDependencies() {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;

    ProcessMetadata process = args.process;
    process.details.questions.forEach((question) {
      responses.add("");
    });

    checkResponseState();
    super.didChangeDependencies();
  }

  @override
  @override
  Widget build(context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    Ent ent = args.ent;
    ProcessMetadata process = args.process;

    if (ent == null) return buildEmptyEntity(context);

    String headerUrl = process.details.headerImage == null
        ? null
        : process.details.headerImage;
    return ScaffoldWithImage(
        headerImageUrl: headerUrl,
        headerTag: headerUrl == null
            ? null
            : makeElementTag(
                entityId: ent.entityReference.entityId,
                cardId: process.meta[META_PROCESS_ID],
                elementId: headerUrl),
        avatarHexSource: process.meta['processId'],
        appBarTitle: "Poll",
        actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(
                  getScaffoldChildren(ctx, ent, process)),
            );
          },
        ));
  }

  List<Widget> actionsBuilder(BuildContext context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    final Ent ent = args.ent;
    return [
      buildShareButton(context, ent),
    ];
  }

  buildTest() {
    double avatarHeight = 120;
    return Container(
      height: avatarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            constraints:
                BoxConstraints(minWidth: avatarHeight, minHeight: avatarHeight),
            child: CircleAvatar(
                backgroundColor: Colors.indigo,
                backgroundImage: NetworkImage(
                    "https://instagram.fmad5-1.fna.fbcdn.net/vp/564db12bde06a8cb360e31007fd049a6/5DDF1906/t51.2885-19/s150x150/13167299_1084444071617255_680456677_a.jpg?_nc_ht=instagram.fmad5-1.fna.fbcdn.net")),
          ),
        ],
      ),
    );
  }

  getScaffoldChildren(BuildContext context, Ent ent, ProcessMetadata process) {
    List<Widget> children = [];
    //children.add(buildTest());
    children.add(buildTitle(context, ent, process));
    children.add(Summary(
      text: process.details.description['default'],
      maxLines: 5,
    ));
    children.add(buildRawItem(context, process));
    children.addAll(buildQuestions(context, process));
    children.add(Section());
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton());

    return children;
  }

  buildTitle(BuildContext context, Ent ent, ProcessMetadata process) {
    String title = process.details.title['default'];
    return ListItem(
      // mainTextTag: makeElementTag(entityId: ent.entityReference.entityId, cardId: process.meta[META_PROCESS_ID], elementId: process.details.headerImage)
      mainText: process.details.title['default'],
      secondaryText: process.meta['entityId'],
      isTitle: true,
      rightIcon: null,
      isBold: true,
      //avatarUrl: ent.entityMetadata.media.avatar,
      //avatarText: process.details.title['default'],
      //avatarHexSource: ent.entitySummary.entityId,
      mainTextFullWidth: true,
    );
  }

  buildRawItem(BuildContext context, ProcessMetadata process) {
    return ListItem(
      icon: FeatherIcons.code,
      mainText: "Raw details",
      onTap: () {
        Navigator.pushNamed(context, "/entity/participation/process/raw",
            arguments: process);
      },
      disabled: true,
    );
  }

  setResponse(int questionIndex, String value) {
    setState(() {
      responses[questionIndex] = value;
    });

    checkResponseState();
  }

  checkResponseState() {
    bool allGood = true;
    int idx = 1;
    for (final response in responses) {
      if (response == '') {
        allGood = false;
        setState(() {
          responsesAreValid = false;
          responsesStateMessage = 'Question #$idx needs to be answered';
        });
        break;
      }
      idx++;
    }

    if (allGood) {
      setState(() {
        responsesAreValid = true;
        responsesStateMessage = '';
      });
    }
  }

  buildSubmitVoteButton() {
    return Padding(
      padding: EdgeInsets.all(paddingPage),
      child: BaseButton(
          text: "Submit",
          isSmall: false,
          style: BaseButtonStyle.FILLED,
          purpose: Purpose.HIGHLIGHT,
          isDisabled: responsesAreValid == false,
          onTap: () {}),
    );
  }

  buildSubmitInfo() {
    return responsesAreValid == false
        ? ListItem(
            mainText: responsesStateMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          )
        : ListItem(
            mainText: responsesStateMessage,
            rightIcon: null,
          );
  }

  buildShareButton(BuildContext context, Ent ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: ent.entityReference.entityId));
          showMessage("Identity ID copied on the clipboard",
              context: context, purpose: Purpose.GUIDE);
        });
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        body: Center(
          child: Text("(No entity)"),
        ));
  }

  List<Widget> buildQuestions(BuildContext ctx, ProcessMetadata process) {
    if (process.details.questions.length == 0) {
      return [buildError("No questions defined")];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Details_Question question
        in process.details.questions) {
      items.addAll(buildQuestion(question, questionIndex));
      questionIndex++;
    }

    return items;
  }

  List<Widget> buildQuestion(
      ProcessMetadata_Details_Question question, int questionIndex) {
    List<Widget> items = new List<Widget>();

    if (question.type == "single-choice") {
      items.add(Section(text: (questionIndex + 1).toString()));
      items.add(buildQuestionTitle(question, questionIndex));

      List<Widget> options = new List<Widget>();
      question.voteOptions.forEach((voteOption) {
        options.add(Padding(
          padding: EdgeInsets.fromLTRB(paddingPage, 0, paddingPage, 0),
          child: ChoiceChip(
            backgroundColor: colorLightGuide,
            selectedColor: colorBlue,
            padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
            label: Text(
              voteOption.title['default'],
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
              style: TextStyle(
                  fontSize: fontSizeSecondary,
                  fontWeight: fontWeightRegular,
                  color: responses[questionIndex] == voteOption.value
                      ? Colors.white
                      : colorDescription),
            ),
            selected: responses[questionIndex] == voteOption.value,
            onSelected: (bool selected) {
              if (selected) {
                setResponse(questionIndex, voteOption.value);
              }
            },
          ),
        ));
      });

      items.add(
        Column(
          children: options,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    } else {
      String questionType = question.type;
      buildError("Question type not supported: $questionType");
    }
    return items;
  }

  buildError(String error) {
    ListItem(
      mainText: "Error: $error",
      rightIcon: null,
      icon: FeatherIcons.alertCircle,
      purpose: Purpose.DANGER,
    );
  }

  buildQuestionTitle(ProcessMetadata_Details_Question question, int index) {
    return ListItem(
      mainText: question.question['default'],
      secondaryText: question.description['default'],
      secondaryTextMultiline: 100,
      rightIcon: null,
    );
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}