//
//  MisDesafios.h
//  Proyecto2HuellaDeCarbono
//
//  Created by Alejandro Francisco Ruiz Guerrero on 30/11/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MisDesafios : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *Desafio1Texto;
@property (weak, nonatomic) IBOutlet UILabel *Desafio2Texto;
- (IBAction)BotonOtros:(id)sender;
- (IBAction)BotonGuardar:(id)sender;
- (IBAction)BotonCompletado:(id)sender;

@end

NS_ASSUME_NONNULL_END
