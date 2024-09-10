import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';

class SunmiService {
  // initialize sunmi printer
  Future<void> initialize() async {
    await SunmiPrinter.bindingPrinter();
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
  }

  // print image
  // Future<void> printLogoImage() async {
  //   await SunmiPrinter.lineWrap(1); // creates one line space
  //   Uint8List byte = await _getImageFromAsset('assets/images/logo.png');
  //   await SunmiPrinter.printImage(byte);
  //   await SunmiPrinter.lineWrap(1); // creates one line space
  // }

  // Future<Uint8List> readFileBytes(String path) async {
  //   ByteData fileData = await rootBundle.load(path);
  //   Uint8List fileUnit8List = fileData.buffer
  //       .asUint8List(fileData.offsetInBytes, fileData.lengthInBytes);
  //   return fileUnit8List;
  // }

  // Future<Uint8List> _getImageFromAsset(String iconPath) async {
  //   return await readFileBytes(iconPath);
  // }

  // print text passed as parameter
  Future<void> printText(String text) async {
    await SunmiPrinter.printText(text,
        style: SunmiStyle(
          fontSize: SunmiFontSize.MD,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ));
  }

  // // print text as qrcode
  // Future<void> printQRCode(String text) async {
  //   // set alignment center
  //   await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
  //   await SunmiPrinter.lineWrap(1); // creates one line space
  //   await SunmiPrinter.printQRCode(text);
  //   await SunmiPrinter.lineWrap(4); // creates one line space
  // }

  // print row and 2 columns
  Future<void> printRowAndColumns({
    String? column1 = "column 1",
    String? column2 = "column 2",
  }) async {
    // set alignment center
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

    // prints a row with 3 columns
    // total width of columns should be 30
    await SunmiPrinter.printRow(cols: [
      ColumnMaker(
        text: "$column1",
        width: 13,
        align: SunmiPrintAlign.LEFT,
      ),
      ColumnMaker(
        text: "$column2",
        width: 13,
        align: SunmiPrintAlign.CENTER,
      ),
    ]);
  }

  /* its important to close the connection with the printer once you are done */
  Future<void> closePrinter() async {
    await SunmiPrinter.unbindingPrinter();
  }

  // print one structure
  Future<void> printReceipt(
      String license,
      String address,
      String name,
      String plateno,
      String vehicle,
      String owner,
      String owneraddress,
      List violations,
      String id) async {
    await initialize();

    // await printLogoImage();

    printText('TRAFFIC CITATION TICKET');
    await printText(DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.now()));
    await printText(id);
    await printRowAndColumns(
      column1: "License:",
      column2: license,
    );
    await printRowAndColumns(
      column1: "Name:",
      column2: name,
    );
    await printRowAndColumns(
      column1: "Address:",
      column2: address,
    );
    await printRowAndColumns(
      column1: "Plate Number:",
      column2: plateno,
    );
    await printRowAndColumns(
      column1: "Vehicle Type:",
      column2: vehicle,
    );
    await printRowAndColumns(
      column1: "Owner Name:",
      column2: owner,
    );
    await printRowAndColumns(
      column1: "Owner Address:",
      column2: owneraddress,
    );

    await printRowAndColumns(
      column1: "Violations:",
      column2: '',
    );

    for (int i = 0; i < violations.length; i++) {
      await printRowAndColumns(
        column1: violations[i]['violation'],
        column2: violations[i]['fine'],
      );
    }

    await SunmiPrinter.cut();

    await closePrinter();
  }
}
