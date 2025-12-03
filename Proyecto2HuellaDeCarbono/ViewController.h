//
//  ViewController.h
//  Proyecto2HuellaDeCarbono
//
//  Created by Alejandro Francisco Ruiz Guerrero on 29/11/25.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *HuellaCarbonoScore;
@property (weak, nonatomic) IBOutlet UILabel *RachaCount;
@property (weak, nonatomic) IBOutlet UILabel *ActividadesCount;
@property (weak, nonatomic) IBOutlet UIView *NavBar;
@property (weak, nonatomic) IBOutlet UIView *RachaView;
@property (weak, nonatomic) IBOutlet UIView *ActividadesView;
@property (weak, nonatomic) IBOutlet UIButton *EstadisticasButton;
@property (weak, nonatomic) IBOutlet UIButton *ObjetivosButton;

@property (weak, nonatomic) IBOutlet UILabel *GenericLabels;
@property (weak, nonatomic) IBOutlet UIButton *AgregarActividadButton;
@property (weak, nonatomic) IBOutlet UILabel *TitleBanner;

@end

