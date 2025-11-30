#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface Actividad : NSObject
@property (nonatomic, assign) NSInteger actividadId;
@property (nonatomic, strong) NSDate *fecha;
@property (nonatomic, strong) NSString *tipoAct;
@property (nonatomic, assign) CGFloat cantidad;
@end

@interface DatabaseManager : NSObject

+ (instancetype)sharedManager;
- (BOOL)initializeDatabase;
- (void)closeDatabase;

// CRUD - Actividad
- (BOOL)insertActividad:(Actividad *)actividad;
- (NSArray<Actividad *> *)getAllActividades;
- (NSArray<Actividad *> *)getActividadesHoy;
- (NSArray<Actividad *> *)getActividadesByTipo:(NSString *)tipo;
- (NSArray<Actividad *> *)getActividadesByFecha:(NSDate *)fecha;
- (BOOL)updateActividad:(Actividad *)actividad;
- (BOOL)deleteActividad:(NSInteger)actividadId;

// Cálculo de CO2
- (float)calcularCO2ParaActividad:(NSString *)tipoActividad cantidad:(float)cantidad;

// Racha
- (NSInteger) getRachaCount;
@end

NS_ASSUME_NONNULL_END
