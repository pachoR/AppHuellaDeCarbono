#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface Actividad : NSObject
@property (nonatomic, assign) NSInteger actividadId;
@property (nonatomic, strong) NSDate *fecha;
@property (nonatomic, strong) NSString *tipoAct;
@property (nonatomic, assign) CGFloat cantidad;
@end

@interface Desafio : NSObject
@property (nonatomic, assign) NSInteger desafioId;
@property (nonatomic, strong) NSString *desafioUno;
@property (nonatomic, strong) NSString *desafioDos;
@property (nonatomic, strong) NSDate *fechaCreacion;
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

// CRUD - Desafio
- (BOOL)insertDesafio:(Desafio *)desafio;
- (Desafio *)getDesafioActual;
- (NSArray<Desafio *> *)getAllDesafios;
- (BOOL)updateDesafio:(Desafio *)desafio;
- (BOOL)deleteDesafio:(NSInteger)desafioId;
- (BOOL)saveDesafiosDiarios:(NSString *)desafioUno desafioDos:(NSString *)desafioDos;

// Cálculo de CO2
- (float)calcularCO2ParaActividad:(NSString *)tipoActividad cantidad:(float)cantidad;

// Racha
- (NSInteger)getRachaCount;

// Agrega estos métodos al final del interface
- (NSDictionary *)getDatosSemanalesCO2;
- (NSDictionary *)getDatosMensualesCO2;
@end

NS_ASSUME_NONNULL_END
