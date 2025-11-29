//
//  DatabaseManager.h
//  EcoHuella
//
//  Gestor de base de datos local usando SQLite
//  Maneja todas las operaciones CRUD para hábitos sostenibles
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

// Modelos de datos
@interface HabitoSostenible : NSObject
@property (nonatomic, assign) NSInteger habitoId;
@property (nonatomic, strong) NSString *categoria; // Transporte, Reciclaje, Energia, Alimentacion
@property (nonatomic, strong) NSString *actividad; // Descripción específica
@property (nonatomic, assign) float cantidadCO2Ahorrado; // kg de CO2
@property (nonatomic, strong) NSDate *fecha;
@property (nonatomic, strong) NSString *notas;
@end

@interface DesafioEcologico : NSObject
@property (nonatomic, assign) NSInteger desafioId;
@property (nonatomic, strong) NSString *titulo;
@property (nonatomic, strong) NSString *descripcion;
@property (nonatomic, assign) NSInteger duracionDias;
@property (nonatomic, assign) NSInteger progresoActual;
@property (nonatomic, assign) BOOL completado;
@property (nonatomic, strong) NSDate *fechaInicio;
@property (nonatomic, assign) float recompensaPuntos;
@end

@interface EstadisticaDiaria : NSObject
@property (nonatomic, strong) NSDate *fecha;
@property (nonatomic, assign) float totalCO2Ahorrado;
@property (nonatomic, assign) NSInteger numeroActividades;
@property (nonatomic, assign) NSInteger racha; // días consecutivos
@end

// Gestor principal de base de datos
@interface DatabaseManager : NSObject

// Singleton
+ (instancetype)sharedManager;

// Inicialización
- (BOOL)initializeDatabase;
- (void)closeDatabase;

// CRUD - Hábitos Sostenibles
- (BOOL)insertHabito:(HabitoSostenible *)habito;
- (NSArray<HabitoSostenible *> *)getAllHabitos;
- (NSArray<HabitoSostenible *> *)getHabitosByFecha:(NSDate *)fecha;
- (NSArray<HabitoSostenible *> *)getHabitosByCategoria:(NSString *)categoria;
- (BOOL)updateHabito:(HabitoSostenible *)habito;
- (BOOL)deleteHabito:(NSInteger)habitoId;

// CRUD - Desafíos Ecológicos
- (BOOL)insertDesafio:(DesafioEcologico *)desafio;
- (NSArray<DesafioEcologico *> *)getAllDesafios;
- (NSArray<DesafioEcologico *> *)getDesafiosActivos;
- (BOOL)updateDesafioProgreso:(NSInteger)desafioId nuevoProgreso:(NSInteger)progreso;
- (BOOL)completarDesafio:(NSInteger)desafioId;
- (BOOL)deleteDesafio:(NSInteger)desafioId;

// Estadísticas y Reportes
- (EstadisticaDiaria *)getEstadisticasDia:(NSDate *)fecha;
- (NSArray<EstadisticaDiaria *> *)getEstadisticasSemana:(NSDate *)fechaInicio;
- (float)getTotalCO2AhorradoMes:(NSDate *)mes;
- (NSInteger)getRachaActual;
- (NSDictionary *)getDistribucionPorCategoria; // Retorna {categoria: totalCO2}

// Cálculos de Huella de Carbono
- (float)calcularHuellaCarbono:(NSString *)tipoActividad cantidad:(float)cantidad;

@end
