// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
// import 'package:line_icons/line_icons.dart';

// /*
//   CURRENT ISSUES:
//   1. Can't convert colors to html
//   2. video sizes are not working properly

//   PROS:
//   1. Properly maintained
//   2. Fast, Fluent and popular
// */

// class CustomQuillEditor extends StatefulWidget {
//   CustomQuillEditor({Key? key, this.height, this.initialText, required this.controller, required this.title}) : super(key: key);

//   final double? height;
//   final String? initialText;
//   final QuillController controller;
//   final String title;

//   @override
//   State<CustomQuillEditor> createState() => _CustomQuillEditorState();
// }

// class _CustomQuillEditorState extends State<CustomQuillEditor> {
//   final ScrollController scrollController = ScrollController();

//   @override
//   void initState() {
//     if (widget.initialText != null && widget.initialText != '') {
//       widget.controller.document = Document.fromDelta(Document.fromHtml(widget.initialText.toString()).toDelta());
//     }
//     super.initState();
//   }

//   @override
//   void dispose() {
//     widget.controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           widget.title,
//           style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           height: widget.height ?? 500,
//           decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.grey.shade300)),
//           child: Column(
//             children: [
//               QuillToolbar.simple(
//                 configurations: QuillSimpleToolbarConfigurations(
//                   controller: widget.controller,
//                   showSearchButton: false,
//                   showSubscript: false,
//                   showSuperscript: false,
//                   showFontFamily: false,
//                   buttonOptions: QuillSimpleToolbarButtonOptions(),
//                   embedButtons: FlutterQuillEmbeds.toolbarButtons(videoButtonOptions: null, imageButtonOptions: null),
//                   customButtons: [
//                     _imageButton(),
//                     _videoButton(),
//                   ],
//                 ),
//               ),

//               // QuillToolbar(
//               //   configurations: QuillToolbarConfigurations(sharedConfigurations: QuillSharedConfigurations()),
//               //   child: SingleChildScrollView(
//               //     scrollDirection: Axis.horizontal,
//               //     child: Row(
//               //       children: [
//               //         QuillToolbarHistoryButton(
//               //           isUndo: true,
//               //           controller: widget.controller,
//               //         ),
//               //         QuillToolbarHistoryButton(
//               //           isUndo: false,
//               //           controller: widget.controller,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           options: const QuillToolbarToggleStyleButtonOptions(),
//               //           controller: widget.controller,
//               //           attribute: Attribute.bold,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           options: const QuillToolbarToggleStyleButtonOptions(),
//               //           controller: widget.controller,
//               //           attribute: Attribute.italic,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           controller: widget.controller,
//               //           attribute: Attribute.underline,
//               //         ),
//               //         QuillToolbarClearFormatButton(
//               //           controller: widget.controller,
//               //         ),
//               //         const VerticalDivider(),
//               //         QuillToolbarImageButton(
//               //           controller: widget.controller,
//               //         ),
//               //         QuillToolbarCameraButton(
//               //           controller: widget.controller,
//               //         ),
//               //         QuillToolbarVideoButton(
//               //           controller: widget.controller,
//               //         ),
//               //         const VerticalDivider(),
//               //         QuillToolbarColorButton(
//               //           controller: widget.controller,
//               //           isBackground: false,
//               //         ),
//               //         QuillToolbarColorButton(
//               //           controller: widget.controller,
//               //           isBackground: true,
//               //         ),
//               //         // const VerticalDivider(),
//               //         // QuillToolbarSelectHeaderStyleButton(
//               //         //   controller: widget.controller,

//               //         // ),
//               //         const VerticalDivider(),
//               //         QuillToolbarToggleCheckListButton(
//               //           controller: widget.controller,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           controller: widget.controller,
//               //           attribute: Attribute.ol,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           controller: widget.controller,
//               //           attribute: Attribute.ul,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           controller: widget.controller,
//               //           attribute: Attribute.inlineCode,
//               //         ),
//               //         QuillToolbarToggleStyleButton(
//               //           controller: widget.controller,
//               //           attribute: Attribute.blockQuote,
//               //         ),
//               //         QuillToolbarIndentButton(
//               //           controller: widget.controller,
//               //           isIncrease: true,
//               //         ),
//               //         QuillToolbarIndentButton(
//               //           controller: widget.controller,
//               //           isIncrease: false,
//               //         ),
//               //         const VerticalDivider(),
//               //         QuillToolbarLinkStyleButton(controller: widget.controller),
//               //       ],
//               //     ),
//               //   ),
//               // ),
//               const Divider(),
//               Expanded(
//                 child: QuillEditor.basic(
//                   scrollController: scrollController,
//                   configurations: QuillEditorConfigurations(
//                     controller: widget.controller,
//                     embedBuilders: FlutterQuillEmbeds.editorWebBuilders(),
//                     placeholder: 'Enter Description',
//                     expands: true,
//                     padding: const EdgeInsets.all(16),
//                     readOnly: false,
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   QuillToolbarCustomButtonOptions _imageButton() {
//     return QuillToolbarCustomButtonOptions(
//       icon: Icon(LineIcons.image, size: 20),
//       tooltip: 'Image',
//       onPressed: () {
//         var imageCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return AlertDialog(
//                 actions: [
//                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                   TextButton(
//                     child: const Text('Add'),
//                     onPressed: () {
//                       if (formKey.currentState!.validate()) {
//                         formKey.currentState!.save();
//                         widget.controller.insertImageBlock(imageSource: imageCtlr.text);
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                 ],
//                 title: const Text('Image URL'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Form(
//                       key: formKey,
//                       child: TextFormField(
//                         controller: imageCtlr,
//                         decoration: InputDecoration(
//                           hintText: 'Enter Image Url',
//                           suffixIcon: IconButton(
//                             icon: Icon(Icons.clear),
//                             onPressed: () => imageCtlr.clear(),
//                           ),
//                         ),
//                         validator: ((value) {
//                           if (value!.isEmpty) return 'Value is empty';
//                           bool validURL = Uri.parse(value).isAbsolute;
//                           if (!validURL) return "Invalid URL";
//                           return null;
//                         }),
//                       ),
//                     )
//                   ],
//                 ),
//               );
//             }));
//       },
//     );
//   }

//   QuillToolbarCustomButtonOptions _videoButton() {
//     return QuillToolbarCustomButtonOptions(
//       icon: Icon(LineIcons.youtube, size: 20),
//       tooltip: 'Video',
//       onPressed: () {
//         var videoTextCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return AlertDialog(
//                 actions: [
//                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                   TextButton(
//                     child: const Text('Add'),
//                     onPressed: () {
//                       if (formKey.currentState!.validate()) {
//                         formKey.currentState!.save();
//                         widget.controller.insertVideoBlock(videoUrl: videoTextCtlr.text);
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                 ],
//                 title: const Text('Video URL'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Form(
//                       key: formKey,
//                       child: TextFormField(
//                         controller: videoTextCtlr,
//                         decoration: InputDecoration(
//                           hintText: 'Enter Video URL',
//                           suffixIcon: IconButton(
//                             icon: Icon(Icons.clear),
//                             onPressed: () => videoTextCtlr.clear(),
//                           ),
//                         ),
//                         validator: ((value) {
//                           if (value!.isEmpty) return 'Value is empty';
//                           bool validURL = Uri.parse(value).isAbsolute;
//                           if (!validURL) return "Invalid URL";
//                           return null;
//                         }),
//                       ),
//                     )
//                   ],
//                 ),
//               );
//             }));
//       },
//     );
//   }
// }
