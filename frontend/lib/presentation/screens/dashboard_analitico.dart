import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/estudiantes_service.dart';

class DashboardAnalitico extends StatefulWidget {
  final int estudianteId;
  final String nombreEstudiante;

  const DashboardAnalitico({
    Key? key,
    required this.estudianteId,
    required this.nombreEstudiante,
  }) : super(key: key);

  @override
  _DashboardAnaliticoState createState() => _DashboardAnaliticoState();
}

class _DashboardAnaliticoState extends State<DashboardAnalitico> {
  bool _cargando = true;
  int _totalInteracciones = 0;
  List<dynamic> _topPalabras = [];

  final List<Color> _colores = [
    const Color(0xFF4361EE),
    const Color(0xFF3A0CA3),
    const Color(0xFF4CC9F0),
    const Color(0xFFF72585),
    const Color(0xFFFFB703),
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  // --- LÓGICA DE ESTADO LIMPIA ---
  Future<void> _cargarEstadisticas() async {
    try {
      final data = await EstudiantesService.obtenerEstadisticas(
        widget.estudianteId,
      );
      setState(() {
        _totalInteracciones = data['total_interacciones'];
        _topPalabras = data['top_palabras'];
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // --- HU-11: GENERACIÓN DE REPORTE CLÍNICO EN PDF ---
  Future<void> _generarYCompartirPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Reporte Clínico SAAC',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'Evolución del Paciente',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Paciente: ${widget.nombreEstudiante}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Fecha de emisión: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Resumen de Actividad',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total de pictogramas presionados en el tablero: $_totalInteracciones',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Vocabulario Frecuente (Intereses)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue100,
                ),
                headerHeight: 30,
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                },
                headers: ['Palabra / Categoría', 'Frecuencia de Uso'],
                data: _topPalabras
                    .map(
                      (item) => [
                        item['palabra'].toString().toUpperCase(),
                        '${item['cantidad']} veces',
                      ],
                    )
                    .toList(),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Documento generado automáticamente por el Sistema SAAC',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${widget.nombreEstudiante.replaceAll(" ", "_")}.pdf',
    );
  }

  // --- INTERFAZ GRÁFICA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Progreso Clínico',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: _cargando || _topPalabras.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _generarYCompartirPDF,
              backgroundColor: const Color(0xFFF72585),
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Exportar PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4361EE)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paciente: ${widget.nombreEstudiante}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Métricas de uso del tablero y vocabulario.',
                      style: TextStyle(color: Color(0xFF8D99AE)),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _totalInteracciones.toString(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Pictogramas presionados',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_topPalabras.isEmpty)
                      const Center(
                        child: Text(
                          'El estudiante aún no ha usado el tablero.',
                          style: TextStyle(color: Color(0xFF8D99AE)),
                        ),
                      )
                    else ...[
                      const Text(
                        'Vocabulario más frecuente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2D42),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4361EE).withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: List.generate(_topPalabras.length, (i) {
                              final item = _topPalabras[i];
                              final double porcentaje =
                                  (item['cantidad'] / _totalInteracciones) *
                                  100;
                              return PieChartSectionData(
                                color: _colores[i % _colores.length],
                                value: item['cantidad'].toDouble(),
                                title: '${porcentaje.toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_topPalabras.length, (i) {
                        final item = _topPalabras[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: _colores[i % _colores.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    item['palabra'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${item['cantidad']} veces',
                                style: const TextStyle(
                                  color: Color(0xFF8D99AE),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
