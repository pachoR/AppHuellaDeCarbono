#import <UIKit/UIKit.h>
@import DGCharts;

NS_ASSUME_NONNULL_BEGIN

@interface Estadisticas : UIViewController
- (IBAction)SemanalMensualSegControl:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *GraphView;
@property (strong, nonatomic) BarChartView *chartView; // Cambiado de weak a strong
@end

NS_ASSUME_NONNULL_END
