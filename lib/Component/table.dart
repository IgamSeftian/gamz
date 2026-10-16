import 'package:flutter/material.dart';

/// Contoh tabel sederhana yang ditampilkan pada halaman utama.
class TableExample extends StatelessWidget {
  const TableExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      //border: TableBorder.all( ),
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(64),
      },
      // defaultVerticalAlignment: .middle,
      children: <TableRow>[
        TableRow(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 205, 239, 243),
          ),
          children: <Widget>[
            Container(height: 32, color: Colors.green),
            TableCell(
              //verticalAlignment: .top,
              child: Container(
                height: 32,
                width: 32,
                color: Colors.transparent,
              ),
            ),
            Container(height: 64, color: Colors.blue),
          ],
        ),
        TableRow(
          decoration: const BoxDecoration(color: Colors.lightBlueAccent),
          children: <Widget>[
            Container(height: 128, width: 128, color: Colors.purple),
            Container(height: 32, color: Colors.yellow),
            Center(
              child: Container(
                height: 32,
                width: 32,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
