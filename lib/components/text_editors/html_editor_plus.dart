// import 'package:flutter/material.dart';
// import 'package:html_editor_plus/html_editor.dart';
// import 'package:line_icons/line_icons.dart';
// import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'package:youtube_parser/youtube_parser.dart';

// /*
//   Imoroved version of html_editor_enhanced
// */

// class CustomHtmlEditoPlus extends StatefulWidget {
//   final HtmlEditorController controller;
//   final String? initialText;
//   final double? height;

//   const CustomHtmlEditoPlus({super.key, required this.controller, this.initialText, this.height});

//   @override
//   State<CustomHtmlEditoPlus> createState() => _CustomHtmlEditoPlusState();
// }

// class _CustomHtmlEditoPlusState extends State<CustomHtmlEditoPlus> {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Description',
//           style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           height: widget.height ?? 500,
//           decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
//           child: HtmlEditor(
//             controller: widget.controller,
//             otherOptions: const OtherOptions(
//               height: 550,
//             ),
//             htmlEditorOptions: HtmlEditorOptions(
//               autoAdjustHeight: true,
//               spellCheck: true,
//               hint: 'Enter description',
//               shouldEnsureVisible: false,
//               initialText: widget.initialText,
//             ),
//             htmlToolbarOptions: HtmlToolbarOptions(
//               initiallyExpanded: false,
//               separatorWidget: Container(),
//               defaultToolbarButtons: [
//                 const OtherButtons(help: false, fullscreen: false, paste: false, copy: false),
//                 const StyleButtons(),
//                 const FontSettingButtons(fontName: false),
//                 const FontButtons(subscript: false, superscript: false, clearAll: false),
//                 const ListButtons(listStyles: false),
//                 const ParagraphButtons(textDirection: false, decreaseIndent: false, increaseIndent: false),
//                 const ColorButtons(),
//                 const InsertButtons(
//                   audio: false,
//                   otherFile: false,
//                   table: true,
//                   video: false,
//                   picture: false,
//                 ),
//               ],
//               customToolbarInsertionIndices: [13],
//               customToolbarButtons: [
//                 InkWell(
//                   child: Container(
//                     padding: const EdgeInsets.all(5),
//                     decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(0)),
//                     child: const Icon(
//                       LineIcons.image,
//                       size: 25,
//                     ),
//                   ),
//                   onTap: () => _openImageDialog(),
//                 ),
//                 InkWell(
//                   child: Container(
//                     padding: const EdgeInsets.all(5),
//                     decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(0)),
//                     child: const Icon(
//                       LineIcons.youtube,
//                       size: 25,
//                     ),
//                   ),
//                   onTap: () => _openYoutubeDialog(),
//                 ),
//                 InkWell(
//                   child: Container(
//                     padding: const EdgeInsets.all(5),
//                     decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(0)),
//                     child: const Icon(
//                       LineIcons.video,
//                       size: 25,
//                     ),
//                   ),
//                   onTap: () => _openNetworkVideoDialog(),
//                 ),
//               ],
//               gridViewHorizontalSpacing: 0,
//               videoExtensions: ['mp4'],
//               renderBorder: true,
//               toolbarPosition: ToolbarPosition.aboveEditor, //by default
//               toolbarType: ToolbarType.nativeScrollable,

//             ),
//             // callbacks: Callbacks(onInit: () {
//             //   widget.controller.setFullScreen();
//             // }),
//           ),
//         ),
//       ],
//     );
//   }

//   _openYoutubeDialog() {
//     var youtubeCtlr = TextEditingController();
//     var formKey = GlobalKey<FormState>();
//     showDialog(
//         context: context,
//         builder: ((context) {
//           return PointerInterceptor(
//             child: AlertDialog(
//               actions: [
//                 TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Text('Cancel')),
//                 TextButton(
//                   onPressed: () {
//                     if (formKey.currentState!.validate()) {
//                       formKey.currentState!.save();
//                       String? videoId = getIdFromUrl(youtubeCtlr.text);
//                       widget.controller.insertHtml(
//                           '''<iframe width="560" height="315" src="https://www.youtube.com/embed/$videoId" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen=""></iframe><br>''');
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: const Text('Add'),
//                 ),
//               ],
//               title: const Text('Youtube Video Url'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Form(
//                     key: formKey,
//                     child: TextFormField(
//                       controller: youtubeCtlr,
//                       decoration: InputDecoration(
//                         hintText: 'Enter Youtube video Url',
//                         label: const Text('URL'),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.clear),
//                           onPressed: () => youtubeCtlr.clear(),
//                         ),
//                       ),
//                       validator: ((value) {
//                         if (value!.isEmpty) return 'Value is empty';
//                         String? videoId = getIdFromUrl(youtubeCtlr.text);
//                         if (videoId == null) return "Invalid video ID";
//                         return null;
//                       }),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           );
//         }));
//   }

//   _openImageDialog() {
//     var imageCtlr = TextEditingController();
//     var formKey = GlobalKey<FormState>();
//     showDialog(
//         context: context,
//         builder: ((context) {
//           return PointerInterceptor(
//             child: AlertDialog(
//               actions: [
//                 TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Text('Cancel')),
//                 TextButton(
//                     onPressed: () {
//                       if (formKey.currentState!.validate()) {
//                         formKey.currentState!.save();
//                         widget.controller.insertNetworkImage(imageCtlr.text);
//                         Navigator.pop(context);
//                       }
//                     },
//                     child: const Text('Add')),
//               ],
//               title: const Text('Image URL'),
//               content: Form(
//                 key: formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TextFormField(
//                       controller: imageCtlr,
//                       decoration: InputDecoration(
//                         hintText: 'Enter Image Url',
//                         label: const Text('URL'),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.clear),
//                           onPressed: () => imageCtlr.clear(),
//                         ),
//                       ),
//                       validator: ((value) {
//                         if (value!.isEmpty) return 'Value is empty';
//                         bool validURL = Uri.parse(value).isAbsolute;
//                         if (!validURL) return "Invalid URL";
//                         return null;
//                       }),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }));
//   }

//   _openNetworkVideoDialog() {
//     var videoCtlr = TextEditingController();
//     var formKey = GlobalKey<FormState>();
//     showDialog(
//       context: context,
//       builder: ((context) {
//         return PointerInterceptor(
//           child: AlertDialog(
//             actions: [
//               TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: const Text('Cancel')),
//               TextButton(
//                   onPressed: () {
//                     if (formKey.currentState!.validate()) {
//                       formKey.currentState!.save();
//                       widget.controller.insertHtml('''<video width="560" height="315" controls="" src="${videoCtlr.text}"></video><br>''');
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: const Text('Add')),
//             ],
//             title: const Text('Network Video Url'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Form(
//                   key: formKey,
//                   child: TextFormField(
//                     decoration: InputDecoration(
//                       hintText: 'Enter Video URL',
//                       label: const Text('URL'),
//                       suffixIcon: IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () => videoCtlr.clear(),
//                       ),
//                     ),
//                     controller: videoCtlr,
//                     validator: ((value) {
//                       if (value!.isEmpty) return 'Value is empty';
//                       bool validURL = Uri.parse(value).isAbsolute;
//                       if (!validURL) return "Invalid URL";
//                       return null;
//                     }),
//                   ),
//                 )
//               ],
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }
