import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/state-notifier-listener.dart';
import 'package:vocdoni/lib/util.dart';

import 'package:vocdoni/views/poll-packaging.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:intl/intl.dart';

class PollPageArgs {
  EntityModel entity;
  ProcessModel process;
  final int index;
  PollPageArgs(
      {@required this.entity, @required this.process, @required this.index});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  EntityModel entity;
  ProcessModel process;
  int index;
  List<String> choices = [];

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    final PollPageArgs args = ModalRoute.of(context).settings.arguments;
    if (args == null) {
      Navigator.of(context).pop();
      devPrint("Invalid parameters");
      return;
    } else if (!args.process.metadata.hasValue) {
      Navigator.of(context).pop();
      devPrint("Empty process metadata");
      return;
    } else if (entity == args.entity &&
        process == args.process &&
        index == args.index) return;

    entity = args.entity;
    process = args.process;
    index = args.index;

    choices = process.metadata.value.details.questions
        .map((question) => null)
        .cast<String>()
        .toList();

    globalAnalytics.trackPage("PollPage",
        entityId: entity.reference.entityId, processId: process.processId);

    await process
        .refreshHasVoted()
        .then((_) => process.refreshIsInCensus())
        .then((_) => globalAppState.refreshBlockInfo())
        .catchError((err) => devPrint(err)); // Values will refresh if not fresh
  }

  @override
  Widget build(context) {
    if (entity == null) return buildEmptyEntity(context);

    // By the constructor, this.process.metadata is guaranteed to exist

    return StateNotifierListener(
      values: [process.metadata, entity.metadata],
      child: Builder(
        builder: (context) {
          if (process.metadata.hasError || !process.metadata.hasValue)
            return buildErrorScaffold(process.metadata.errorMessage);

          final headerUrl =
              Uri.tryParse(process.metadata.value.details?.headerImage ?? "")
                  ?.toString();

          return ScaffoldWithImage(
            headerImageUrl: headerUrl ?? "",
            headerTag: headerUrl == null
                ? null
                : makeElementTag(
                    entity.reference.entityId, process.processId, index),
            avatarHexSource: process.processId,
            appBarTitle: "Poll",
            actionsBuilder: (context) => [
              buildShareButton(context, entity),
            ],
            builder: Builder(
              builder: (ctx) => SliverList(
                delegate: SliverChildListDelegate(
                  getScaffoldChildren(ctx, entity),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> getScaffoldChildren(BuildContext context, EntityModel entity) {
    List<Widget> children = [];
    if (!process.metadata.hasValue) return children;

    children.add(buildTitle(context, entity));
    children.add(buildSummary());
    children.add(buildPollItem(context));
    children.add(buildCensusItem(context));
    children.add(buildTimeItem(context));
    children.addAll(buildQuestions(context));
    children.add(Section());
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton(context));

    return children;
  }

  Widget buildTitle(BuildContext context, EntityModel entity) {
    if (process.metadata.value == null) return Container();

    final title =
        process.metadata.value.details.title[globalAppState.currentLanguage];

    return StateNotifierListener(
        values: [entity.metadata],
        child: ListItem(
          // mainTextTag: makeElementTag(entityId: ent.reference.entityId, cardId: _process.meta[META_PROCESS_ID], elementId: _process.details.headerImage)
          mainText: title,
          secondaryText: entity.metadata.hasValue
              ? entity.metadata.value.name[globalAppState.currentLanguage]
              : "",
          isTitle: true,
          rightIcon: null,
          isBold: true,
          avatarUrl: entity.metadata.hasValue
              ? entity.metadata.value.media.avatar
              : "",
          avatarText: entity.metadata.hasValue
              ? entity.metadata.value.name[globalAppState.currentLanguage]
              : "",
          avatarHexSource: entity.reference.entityId,
          //avatarHexSource: entity.entitySummary.entityId,
          mainTextFullWidth: true,
        ));
  }

  Widget buildSummary() {
    return Summary(
      text: process
          .metadata.value.details.description[globalAppState.currentLanguage],
      maxLines: 5,
    );
  }

  buildCensusItem(BuildContext context) {
    return StateNotifierListener(
      values: [process.isInCensus],
      child: Builder(builder: (ctx) {
        String text;
        Purpose purpose;
        IconData icon;

        if (process.isInCensus.isLoading) {
          text = "Checking census";
        } else if (process.isInCensus.hasValue) {
          if (process.isInCensus.value) {
            text = "You are in the census";
            purpose = Purpose.GOOD;
            icon = FeatherIcons.check;
          } else {
            text = "You are not in this census";
            purpose = Purpose.DANGER;
            icon = FeatherIcons.x;
          }
        } else if (process.isInCensus.hasError) {
          text = process.isInCensus.errorMessage;
          icon = FeatherIcons.alertTriangle;
        } else {
          text = "Check census state";
        }

        return ListItem(
          icon: FeatherIcons.users,
          mainText: text,
          isSpinning: process.isInCensus.isLoading,
          onTap: () => process.refreshIsInCensus(true),
          rightTextPurpose: purpose,
          rightIcon: icon,
          purpose: process.isInCensus.hasError ? Purpose.DANGER : Purpose.NONE,
        );
      }),
    );
  }

  buildPollItem(BuildContext context) {
    return ListItem(
      icon: FeatherIcons.barChart2,
      mainText: "Not anonymous poll",
      rightIcon: null,
      disabled: false,
    );
  }

  buildTimeItem(BuildContext context) {
    // Rebuild when the reference block changes
    return StateNotifierListener(
      values: [process.metadata, globalAppState.referenceBlockTimestamp],
      child: Builder(builder: (context) {
        if (process.startDate is DateTime &&
            process.startDate.isBefore(DateTime.now())) {
          // display time until start date
          final formattedTime =
              DateFormat("dd/MM H:mm").format(process.startDate) + "h";

          return ListItem(
            icon: FeatherIcons.clock,
            mainText: "Starting on " + formattedTime,
            //secondaryText: "18/09/2019 at 19:00",
            rightIcon: null,
            disabled: false,
          );
        } else if (process.endDate is DateTime) {
          String rowText;
          final formattedTime =
              DateFormat("dd/MM HH:mm").format(process.endDate) + "h";
          if (process.endDate.isBefore(DateTime.now()))
            rowText = "Ended on " + formattedTime;
          else
            rowText = "Ending on " + formattedTime;

          return ListItem(
            icon: FeatherIcons.clock,
            mainText: rowText,
            // secondaryText: "18/09/2019 at 19:00",
            rightIcon: null,
            disabled: false,
          );
        }
        return Container();
      }),
    );
  }

  setChoice(int questionIndex, String value) {
    setState(() {
      choices[questionIndex] = value;
    });
  }

  /// Returns the 0-based index of the next unanswered question.
  /// Returns -1 if all questions have a valid choice
  int getNextPendingChoice() {
    int idx = 0;
    for (final response in choices) {
      if (response is String && response.length > 0) {
        idx++;
        continue; // GOOD
      }
      return idx; // PENDING
    }
    return -1; // ALL GOOD
  }

  buildSubmitVoteButton(BuildContext ctx) {
    // rebuild when isInCensus or hasVoted change
    return StateNotifierListener(
      values: [process.hasVoted, process.isInCensus],
      child: Builder(builder: (ctx) {
        if (process.isInCensus.hasError) {
          return Padding(
              padding: EdgeInsets.all(paddingPage),
              child: BaseButton(
                  text: process.isInCensus.errorMessage,
                  purpose: Purpose.DANGER,
                  isDisabled: true));
        } else if (process.hasVoted.hasValue && process.hasVoted.value) {
          return Container();
        }

        final nextPendingChoice = getNextPendingChoice();
        final cannotVote = nextPendingChoice >= 0 ||
            !process.isInCensus.hasValue ||
            !process.isInCensus.value;

        return Padding(
          padding: EdgeInsets.all(paddingPage),
          child: BaseButton(
              text: "Submit",
              purpose: Purpose.HIGHLIGHT,
              isDisabled: cannotVote,
              onTap: () => onSubmit(ctx, process.metadata)),
        );
      }),
    );
  }

  onSubmit(BuildContext ctx, metadata) async {
    var intAnswers = choices.map(int.parse).toList();

    final newRoute = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            PollPackaging(process: process, choices: intAnswers));
    await Navigator.push(ctx, newRoute);
  }

  buildSubmitInfo() {
    // rebuild when isInCensus or hasVoted change
    return StateNotifierListener(
      values: [process.hasVoted, process.isInCensus],
      child: Builder(builder: (ctx) {
        final nextPendingChoice = getNextPendingChoice();

        if (process.hasVoted.hasValue && process.hasVoted.value) {
          return ListItem(
            mainText: 'Your vote is already registered',
            purpose: Purpose.GOOD,
            rightIcon: null,
          );
        } else if (process.isInCensus.hasValue) {
          if (process.isInCensus.hasValue && process.isInCensus.value) {
            if (nextPendingChoice < 0) return Container(); // all good to go

            return ListItem(
              mainText:
                  'Select your choice for question #${nextPendingChoice + 1}',
              purpose: Purpose.WARNING,
              rightIcon: null,
            );
          }

          return ListItem(
            mainText: "You are not in the census",
            secondaryText:
                "Register to this organization to participate in the future",
            secondaryTextMultiline: 5,
            purpose: Purpose.HIGHLIGHT,
            rightIcon: null,
          );
        } else if (process.isInCensus.hasError) {
          return ListItem(
            mainText: "Your identity cannot be checked within the census",
            mainTextMultiline: 3,
            secondaryText: process.isInCensus.errorMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.hasVoted.hasError) {
          return ListItem(
            mainText: "Your vote status cannot be checked",
            mainTextMultiline: 3,
            secondaryText: process.hasVoted.errorMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.isInCensus.isLoading) {
          return ListItem(
            mainText: "Checking the census",
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else if (process.hasVoted.isLoading) {
          return ListItem(
            mainText: "Checking your vote",
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else {
          return Container(); // unknown error
        }
      }),
    );
  }

  buildShareButton(BuildContext context, EntityModel ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: ent.reference.entityId));
          showMessage("Entity ID copied on the clipboard",
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

  List<Widget> buildQuestions(BuildContext ctx) {
    if (!process.metadata.hasValue ||
        process.metadata.value.details.questions.length == 0) {
      return [];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Details_Question question
        in process.metadata.value.details.questions) {
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
                  color: choices[questionIndex] == voteOption.value
                      ? Colors.white
                      : colorDescription),
            ),
            selected: choices[questionIndex] == voteOption.value,
            onSelected: (bool selected) {
              if (selected) {
                setChoice(questionIndex, voteOption.value);
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
    return ListItem(
      mainText: "Error: $error",
      rightIcon: null,
      icon: FeatherIcons.alertCircle,
      purpose: Purpose.DANGER,
    );
  }

  Widget buildErrorScaffold(String error) {
    return Scaffold(
      body: Center(
        child: Text(
          "Error:\n" + error,
          style: new TextStyle(fontSize: 26, color: Color(0xff888888)),
          textAlign: TextAlign.center,
        ),
      ),
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
