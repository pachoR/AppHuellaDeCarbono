#import <UIKit/UIKit.h>
#import "DatabaseManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface An_adirActividad : UIViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *SegmentTipoActividad;
@property (weak, nonatomic) IBOutlet UILabel *LabelTipoConsumo;
@property (weak, nonatomic) IBOutlet UILabel *IncreaseScore;
@property (weak, nonatomic) IBOutlet UIStepper *stepperControl;
- (IBAction)IncreaseStepper:(id)sender;
- (IBAction)Añadir:(id)sender;
- (IBAction)SegmentTipoActividadChanged:(id)sender;

@end
NS_ASSUME_NONNULL_END
