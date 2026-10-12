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
    super.key,
    required this.estudianteId,
    required this.nombreEstudiante,
  });

  @override
  State<DashboardAnalitico> createState() => _DashboardAnaliticoState();
}

class _DashboardAnaliticoState extends State<DashboardAnalitico> {
  bool _cargando = true;
  int _totalInteracciones = 0;
  List<dynamic> _topPalabras = [];

  final List<Color> _colores = [
    const Color(0xFF4361EE), // Azul
    const Color(0xFFF72585), // Rosa
    const Color(0xFFFFB703), // Amarillo
    const Color(0xFF4CC9F0), // Celeste
    const Color(0xFF3A0CA3), // Morado
    const Color(0xFF10B981), // Verde
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF233C),
          ),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  // --- GENERACIÓN DE REPORTE CLÍNICO EN PDF (REPARADO Y PROFESIONAL) ---
  Future<void> _generarYCompartirPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // 1. CABECERA INSTITUCIONAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reporte de Progreso Clínico',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Sistema Alternativo y Aumentativo de Comunicación',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'Uso Confidencial',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // 2. DATOS DEL PACIENTE Y MÉTRICA HERO
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Datos del Estudiante',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildPdfDatoLinea(
                          'Paciente:',
                          widget.nombreEstudiante,
                        ),
                        _buildPdfDatoLinea(
                          'ID Sistema:',
                          '#${widget.estudianteId.toString().padLeft(4, '0')}',
                        ),
                        _buildPdfDatoLinea(
                          'Fecha de Emisión:',
                          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColors.blue200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Interacciones Totales',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.blue800,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            _totalInteracciones.toString(),
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // 3. TABLA CON BARRAS GRÁFICAS INTEGRADAS
              pw.Text(
                'Análisis de Frecuencia de Vocabulario',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 15),

              if (_topPalabras.isEmpty)
                pw.Text(
                  'Sin registros en el tablero.',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2), // Palabra
                    1: const pw.FlexColumnWidth(1), // Cantidad
                    2: const pw.FlexColumnWidth(1), // Porcentaje
                    3: const pw.FlexColumnWidth(2), // Barra Visual
                  },
                  children: [
                    // Cabecera de tabla
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue100,
                      ),
                      children: [
                        _buildPdfCellHeader('Vocabulario'),
                        _buildPdfCellHeader('Usos'),
                        _buildPdfCellHeader('%'),
                        _buildPdfCellHeader('Proporción'),
                      ],
                    ),
                    // Filas de datos
                    ..._topPalabras.map((item) {
                      double porcentaje =
                          (item['cantidad'] / _totalInteracciones) * 100;
                      return pw.TableRow(
                        children: [
                          _buildPdfCell(
                            item['palabra'].toString().toUpperCase(),
                          ),
                          _buildPdfCell('${item['cantidad']}'),
                          _buildPdfCell('${porcentaje.toStringAsFixed(1)}%'),
                          // Minigráfico de barra integrado en la celda
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 8,
                            ),
                            child: pw.Container(
                              height: 8,
                              width:
                                  porcentaje *
                                  1.5, // Multiplicador para alargar la barrita
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue400,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

              pw.SizedBox(height: 30),

              // 4. INTERPRETACIÓN CLÍNICA AUTOMÁTICA
              if (_topPalabras.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Interpretación Rápida (Autogenerado)',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'El estudiante presenta una intención comunicativa fuertemente orientada hacia "${_topPalabras.first['palabra'].toString().toUpperCase()}", '
                        'representando el ${((_topPalabras.first['cantidad'] / _totalInteracciones) * 100).toStringAsFixed(1)}% '
                        'de sus interacciones totales.',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount} - Generado por SAAC App',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Reporte_Clinico_${widget.nombreEstudiante.replaceAll(" ", "_")}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: const Color(0xFFEF233C),
          ),
        );
      }
    }
  }

  // --- HELPERS PARA EL PDF ---
  pw.Widget _buildPdfDatoLinea(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              etiqueta,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      ),
    );
  }

  // --- INTERFAZ GRÁFICA (APP) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                'Generar Reporte',
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
                padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 100.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. TARJETA HERO ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4361EE,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Paciente',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      widget.nombreEstudiante,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Interacciones Totales',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _totalInteracciones.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.touch_app_rounded,
                                color: Colors.white24,
                                size: 50,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    if (_topPalabras.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.pie_chart_rounded,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'Sin datos registrados',
                              style: TextStyle(
                                color: Color(0xFF8D99AE),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // --- 2. GRÁFICO CIRCULAR (RESTAURADO Y MEJORADO) ---
                      const Text(
                        'Distribución de Vocabulario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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
                              color: const Color(
                                0xFF4361EE,
                              ).withValues(alpha: 0.05),
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
                      const SizedBox(height: 30),

                      // --- 3. NUEVO GRÁFICO: INDICADOR DE ENFOQUE TEMÁTICO ---
                      const Text(
                        'Enfoque Temático (Top 3)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B2D42),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            _topPalabras.length > 3 ? 3 : _topPalabras.length,
                            (i) {
                              final item = _topPalabras[i];
                              final double porcentaje =
                                  (item['cantidad'] / _totalInteracciones);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['palabra']
                                              .toString()
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${(porcentaje * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Color(0xFF8D99AE),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    LinearProgressIndicator(
                                      value: porcentaje,
                                      backgroundColor:
                                          _colores[i % _colores.length]
                                              .withValues(alpha: 0.1),
                                      color: _colores[i % _colores.length],
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- 4. SOLUCIÓN DE ESPACIO: NUBE DE PALABRAS (WRAP) ---
                      const Text(
                        'Vocabulario Detallado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B2D42),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Todas las palabras usadas, organizadas por frecuencia.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8D99AE),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Usamos WRAP en lugar de ListView. Esto acomoda las palabras como botones
                      // pequeños unos al lado de otros, ahorrando MUCHO espacio.
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_topPalabras.length, (i) {
                          final item = _topPalabras[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _colores[i % _colores.length].withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _colores[i % _colores.length].withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      _colores[i % _colores.length],
                                  child: Text(
                                    item['cantidad'].toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item['palabra'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: _colores[i % _colores.length],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
