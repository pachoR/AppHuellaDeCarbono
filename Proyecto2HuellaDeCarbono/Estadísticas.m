#import "Estadísticas.h"
#import "DatabaseManager.h"
@import DGCharts;

@interface Estadisticas ()
@property (nonatomic, strong) NSArray<NSDictionary *> *datosSemanales;
@property (nonatomic, strong) NSArray<NSDictionary *> *datosMensuales;
@property (nonatomic, assign) BOOL mostrandoSemanales;
// La propiedad chartView ya está declarada en el .h como strong
@end

@implementation Estadisticas

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupChart];
    self.mostrandoSemanales = YES;
    [self cargarDatosSemanales];
}

- (void)setupChart {
    // Crear chart view programáticamente dentro del GraphView
    _chartView = [[BarChartView alloc] initWithFrame:self.GraphView.bounds];
    self.chartView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.GraphView addSubview:self.chartView];
    
    // El resto de la configuración permanece igual...
    self.chartView.chartDescription.enabled = NO;
    self.chartView.dragEnabled = NO;
    self.chartView.pinchZoomEnabled = NO;
    self.chartView.doubleTapToZoomEnabled = NO;
    self.chartView.drawGridBackgroundEnabled = NO;
    self.chartView.drawBarShadowEnabled = NO;
    self.chartView.drawValueAboveBarEnabled = YES;
    
    // Configurar eje X
    ChartXAxis *xAxis = self.chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    xAxis.drawGridLinesEnabled = NO;
    xAxis.granularity = 1.0;
    xAxis.labelCount = 7;
    UIColor *axisColor = [UIColor darkGrayColor];
    if (@available(iOS 11.0, *)) {
        UIColor *c = [UIColor colorNamed:@"ThemeAccentDark"];
        if (c) axisColor = c;
    }
    xAxis.labelTextColor = axisColor;
    
    // Configurar eje Y izquierdo
    ChartYAxis *leftAxis = self.chartView.leftAxis;
    leftAxis.drawGridLinesEnabled = YES;
    leftAxis.drawZeroLineEnabled = YES;
    leftAxis.zeroLineColor = [UIColor lightGrayColor];
    leftAxis.gridColor = [UIColor lightGrayColor];
    leftAxis.labelTextColor = axisColor;
    leftAxis.axisMinimum = 0.0;
    
    // Ocultar eje Y derecho
    self.chartView.rightAxis.enabled = NO;
    
    // Ocultar leyenda
    self.chartView.legend.enabled = NO;
}

// El resto de los métodos permanece igual...
- (void)cargarDatosSemanales {
    DatabaseManager *dbManager = [DatabaseManager sharedManager];
    self.datosSemanales = [dbManager getDatosSemanalesCO2];
    [self actualizarChartConDatos:self.datosSemanales esSemanal:YES];
}

- (void)cargarDatosMensuales {
    DatabaseManager *dbManager = [DatabaseManager sharedManager];
    self.datosMensuales = [dbManager getDatosMensualesCO2];
    [self actualizarChartConDatos:self.datosMensuales esSemanal:NO];
}

 - (void)actualizarChartConDatos:(NSArray<NSDictionary *> *)datos esSemanal:(BOOL)esSemanal {
    // 'datos' es un arreglo ordenado de diccionarios con claves "label" y "value"
    NSArray *labels = [datos valueForKey:@"label"];
    NSArray *values = [datos valueForKey:@"value"];

    NSMutableArray *dataEntries = [NSMutableArray array];

    for (int i = 0; i < labels.count; i++) {
        double v = 0.0;
        id val = values[i];
        if ([val respondsToSelector:@selector(doubleValue)]) {
            v = [val doubleValue];
        }
        BarChartDataEntry *entry = [[BarChartDataEntry alloc] initWithX:i y:v];
        [dataEntries addObject:entry];
    }
    
    BarChartDataSet *dataSet = [[BarChartDataSet alloc] initWithEntries:dataEntries label:@"kg CO2"];
    
    NSMutableArray *colors = [NSMutableArray array];
    for (int i = 0; i < dataEntries.count; i++) {
        [colors addObject:[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0]];
    }
    dataSet.colors = colors;
    
    dataSet.drawValuesEnabled = YES;
    dataSet.valueTextColor = [UIColor darkGrayColor];
    dataSet.valueFont = [UIFont systemFontOfSize:10];
    
    BarChartData *chartData = [[BarChartData alloc] initWithDataSet:dataSet];
    chartData.barWidth = 0.6;
    
    self.chartView.xAxis.valueFormatter = [[ChartIndexAxisValueFormatter alloc] initWithValues:labels];
    self.chartView.data = chartData;
    
    [self.chartView animateWithYAxisDuration:1.0 easingOption:ChartEasingOptionEaseOutBack];
}

- (IBAction)SemanalMensualSegControl:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.mostrandoSemanales = YES;
        if (self.datosSemanales) {
            [self actualizarChartConDatos:self.datosSemanales esSemanal:YES];
        } else {
            [self cargarDatosSemanales];
        }
    } else {
        self.mostrandoSemanales = NO;
        if (self.datosMensuales) {
            [self actualizarChartConDatos:self.datosMensuales esSemanal:NO];
        } else {
            [self cargarDatosMensuales];
        }
    }
}

@end
