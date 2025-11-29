//
//  DatabaseManager.m
//  EcoHuella
//
//  Implementación del gestor de base de datos SQLite
//

#import "DatabaseManager.h"

// ============================================
// Implementación de Modelos
// ============================================

@implementation HabitoSostenible
@end

@implementation DesafioEcologico
@end

@implementation EstadisticaDiaria
@end

// ============================================
// Implementación DatabaseManager
// ============================================

@interface DatabaseManager()
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, strong) NSString *databasePath;
@end

@implementation DatabaseManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static DatabaseManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Obtener ruta del directorio de documentos
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _databasePath = [documentsDirectory stringByAppendingPathComponent:@"ecohuella.db"];
        
        NSLog(@"Database path: %@", _databasePath);
    }
    return self;
}

#pragma mark - Inicialización de Base de Datos

- (BOOL)initializeDatabase {
    // Abrir/crear base de datos
    if (sqlite3_open([self.databasePath UTF8String], &_database) != SQLITE_OK) {
        NSLog(@"Error al abrir base de datos: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    // Crear tablas si no existen
    [self createTables];
    
    return YES;
}

- (void)createTables {
    // Tabla de Hábitos Sostenibles
    const char *sqlHabitos =
        "CREATE TABLE IF NOT EXISTS habitos_sostenibles ("
        "habito_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "categoria TEXT NOT NULL, "
        "actividad TEXT NOT NULL, "
        "cantidad_co2_ahorrado REAL DEFAULT 0.0, "
        "fecha DATETIME DEFAULT CURRENT_TIMESTAMP, "
        "notas TEXT);";
    
    // Tabla de Desafíos Ecológicos
    const char *sqlDesafios =
        "CREATE TABLE IF NOT EXISTS desafios_ecologicos ("
        "desafio_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "titulo TEXT NOT NULL, "
        "descripcion TEXT, "
        "duracion_dias INTEGER DEFAULT 7, "
        "progreso_actual INTEGER DEFAULT 0, "
        "completado INTEGER DEFAULT 0, "
        "fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP, "
        "recompensa_puntos REAL DEFAULT 0.0);";
    
    // Tabla de Estadísticas Diarias
    const char *sqlEstadisticas =
        "CREATE TABLE IF NOT EXISTS estadisticas_diarias ("
        "fecha DATE PRIMARY KEY, "
        "total_co2_ahorrado REAL DEFAULT 0.0, "
        "numero_actividades INTEGER DEFAULT 0, "
        "racha INTEGER DEFAULT 0);";
    
    char *errorMsg;
    
    // Ejecutar creación de tablas
    if (sqlite3_exec(_database, sqlHabitos, NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSLog(@"Error creando tabla habitos: %s", errorMsg);
        sqlite3_free(errorMsg);
    }
    
    if (sqlite3_exec(_database, sqlDesafios, NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSLog(@"Error creando tabla desafios: %s", errorMsg);
        sqlite3_free(errorMsg);
    }
    
    if (sqlite3_exec(_database, sqlEstadisticas, NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSLog(@"Error creando tabla estadisticas: %s", errorMsg);
        sqlite3_free(errorMsg);
    }
    
    NSLog(@"Tablas creadas exitosamente");
}

- (void)closeDatabase {
    if (_database) {
        sqlite3_close(_database);
        _database = nil;
    }
}

#pragma mark - CRUD Hábitos Sostenibles

- (BOOL)insertHabito:(HabitoSostenible *)habito {
    const char *sql = "INSERT INTO habitos_sostenibles (categoria, actividad, cantidad_co2_ahorrado, fecha, notas) VALUES (?, ?, ?, ?, ?)";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"Error preparando insert: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    // Bind de parámetros
    sqlite3_bind_text(statement, 1, [habito.categoria UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, [habito.actividad UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_double(statement, 3, habito.cantidadCO2Ahorrado);
    
    // Convertir NSDate a string
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *fechaString = [formatter stringFromDate:habito.fecha];
    sqlite3_bind_text(statement, 4, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(statement, 5, [habito.notas UTF8String], -1, SQLITE_TRANSIENT);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    
    if (success) {
        habito.habitoId = sqlite3_last_insert_rowid(_database);
        [self actualizarEstadisticasDia:habito.fecha conCO2:habito.cantidadCO2Ahorrado];
    }
    
    sqlite3_finalize(statement);
    
    return success;
}

- (NSArray<HabitoSostenible *> *)getAllHabitos {
    NSMutableArray *habitos = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM habitos_sostenibles ORDER BY fecha DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            HabitoSostenible *habito = [self habitoFromStatement:statement];
            [habitos addObject:habito];
        }
    }
    
    sqlite3_finalize(statement);
    return habitos;
}

- (NSArray<HabitoSostenible *> *)getHabitosByFecha:(NSDate *)fecha {
    NSMutableArray *habitos = [NSMutableArray array];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *fechaString = [formatter stringFromDate:fecha];
    
    const char *sql = "SELECT * FROM habitos_sostenibles WHERE DATE(fecha) = ? ORDER BY fecha DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            HabitoSostenible *habito = [self habitoFromStatement:statement];
            [habitos addObject:habito];
        }
    }
    
    sqlite3_finalize(statement);
    return habitos;
}

- (NSArray<HabitoSostenible *> *)getHabitosByCategoria:(NSString *)categoria {
    NSMutableArray *habitos = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM habitos_sostenibles WHERE categoria = ? ORDER BY fecha DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [categoria UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            HabitoSostenible *habito = [self habitoFromStatement:statement];
            [habitos addObject:habito];
        }
    }
    
    sqlite3_finalize(statement);
    return habitos;
}

- (BOOL)updateHabito:(HabitoSostenible *)habito {
    const char *sql = "UPDATE habitos_sostenibles SET categoria = ?, actividad = ?, cantidad_co2_ahorrado = ?, notas = ? WHERE habito_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_text(statement, 1, [habito.categoria UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, [habito.actividad UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_double(statement, 3, habito.cantidadCO2Ahorrado);
    sqlite3_bind_text(statement, 4, [habito.notas UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 5, (int)habito.habitoId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (BOOL)deleteHabito:(NSInteger)habitoId {
    const char *sql = "DELETE FROM habitos_sostenibles WHERE habito_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_int(statement, 1, (int)habitoId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

#pragma mark - CRUD Desafíos

- (BOOL)insertDesafio:(DesafioEcologico *)desafio {
    const char *sql = "INSERT INTO desafios_ecologicos (titulo, descripcion, duracion_dias, progreso_actual, completado, fecha_inicio, recompensa_puntos) VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_text(statement, 1, [desafio.titulo UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, [desafio.descripcion UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 3, (int)desafio.duracionDias);
    sqlite3_bind_int(statement, 4, (int)desafio.progresoActual);
    sqlite3_bind_int(statement, 5, desafio.completado ? 1 : 0);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *fechaString = [formatter stringFromDate:desafio.fechaInicio];
    sqlite3_bind_text(statement, 6, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_double(statement, 7, desafio.recompensaPuntos);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    
    if (success) {
        desafio.desafioId = sqlite3_last_insert_rowid(_database);
    }
    
    sqlite3_finalize(statement);
    return success;
}

- (NSArray<DesafioEcologico *> *)getAllDesafios {
    NSMutableArray *desafios = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM desafios_ecologicos ORDER BY fecha_inicio DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            DesafioEcologico *desafio = [self desafioFromStatement:statement];
            [desafios addObject:desafio];
        }
    }
    
    sqlite3_finalize(statement);
    return desafios;
}

- (NSArray<DesafioEcologico *> *)getDesafiosActivos {
    NSMutableArray *desafios = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM desafios_ecologicos WHERE completado = 0 ORDER BY fecha_inicio DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            DesafioEcologico *desafio = [self desafioFromStatement:statement];
            [desafios addObject:desafio];
        }
    }
    
    sqlite3_finalize(statement);
    return desafios;
}

- (BOOL)updateDesafioProgreso:(NSInteger)desafioId nuevoProgreso:(NSInteger)progreso {
    const char *sql = "UPDATE desafios_ecologicos SET progreso_actual = ? WHERE desafio_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_int(statement, 1, (int)progreso);
    sqlite3_bind_int(statement, 2, (int)desafioId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (BOOL)completarDesafio:(NSInteger)desafioId {
    const char *sql = "UPDATE desafios_ecologicos SET completado = 1 WHERE desafio_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_int(statement, 1, (int)desafioId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (BOOL)deleteDesafio:(NSInteger)desafioId {
    const char *sql = "DELETE FROM desafios_ecologicos WHERE desafio_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_int(statement, 1, (int)desafioId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

#pragma mark - Estadísticas

- (EstadisticaDiaria *)getEstadisticasDia:(NSDate *)fecha {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *fechaString = [formatter stringFromDate:fecha];
    
    const char *sql = "SELECT * FROM estadisticas_diarias WHERE fecha = ?";
    sqlite3_stmt *statement;
    EstadisticaDiaria *estadistica = nil;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            estadistica = [[EstadisticaDiaria alloc] init];
            estadistica.fecha = fecha;
            estadistica.totalCO2Ahorrado = sqlite3_column_double(statement, 1);
            estadistica.numeroActividades = sqlite3_column_int(statement, 2);
            estadistica.racha = sqlite3_column_int(statement, 3);
        }
    }
    
    sqlite3_finalize(statement);
    return estadistica;
}

- (NSArray<EstadisticaDiaria *> *)getEstadisticasSemana:(NSDate *)fechaInicio {
    NSMutableArray *estadisticas = [NSMutableArray array];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    for (int i = 0; i < 7; i++) {
        NSDate *fecha = [fechaInicio dateByAddingTimeInterval:i * 24 * 60 * 60];
        EstadisticaDiaria *est = [self getEstadisticasDia:fecha];
        
        if (!est) {
            est = [[EstadisticaDiaria alloc] init];
            est.fecha = fecha;
            est.totalCO2Ahorrado = 0.0;
            est.numeroActividades = 0;
            est.racha = 0;
        }
        
        [estadisticas addObject:est];
    }
    
    return estadisticas;
}

- (float)getTotalCO2AhorradoMes:(NSDate *)mes {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM"];
    NSString *mesString = [formatter stringFromDate:mes];
    
    const char *sql = "SELECT SUM(cantidad_co2_ahorrado) FROM habitos_sostenibles WHERE strftime('%Y-%m', fecha) = ?";
    sqlite3_stmt *statement;
    float total = 0.0;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [mesString UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            total = sqlite3_column_double(statement, 0);
        }
    }
    
    sqlite3_finalize(statement);
    return total;
}

- (NSInteger)getRachaActual {
    // Obtener racha del día más reciente
    const char *sql = "SELECT racha FROM estadisticas_diarias ORDER BY fecha DESC LIMIT 1";
    sqlite3_stmt *statement;
    NSInteger racha = 0;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            racha = sqlite3_column_int(statement, 0);
        }
    }
    
    sqlite3_finalize(statement);
    return racha;
}

- (NSDictionary *)getDistribucionPorCategoria {
    NSMutableDictionary *distribucion = [NSMutableDictionary dictionary];
    
    const char *sql = "SELECT categoria, SUM(cantidad_co2_ahorrado) as total FROM habitos_sostenibles GROUP BY categoria";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const char *categoria = (const char *)sqlite3_column_text(statement, 0);
            float total = sqlite3_column_double(statement, 1);
            
            NSString *categoriaString = [NSString stringWithUTF8String:categoria];
            [distribucion setObject:@(total) forKey:categoriaString];
        }
    }
    
    sqlite3_finalize(statement);
    return distribucion;
}

#pragma mark - Cálculo de Huella de Carbono

- (float)calcularHuellaCarbono:(NSString *)tipoActividad cantidad:(float)cantidad {
    // Factores de emisión promedio (kg CO2 por unidad)
    NSDictionary *factores = @{
        // Transporte (por km)
        @"auto": @(0.192),
        @"autobus": @(0.089),
        @"bicicleta": @(0.0),
        @"caminar": @(0.0),
        @"metro": @(0.041),
        
        // Energía (por kWh)
        @"electricidad": @(0.475),
        @"gas_natural": @(2.03),
        
        // Reciclaje (ahorro por kg reciclado)
        @"papel": @(-0.9),
        @"plastico": @(-1.5),
        @"vidrio": @(-0.3),
        @"aluminio": @(-9.0),
        
        // Alimentación (por kg)
        @"carne_res": @(27.0),
        @"carne_pollo": @(6.9),
        @"vegetales": @(2.0),
        @"local": @(-0.5) // Ahorro por comprar local
    };
    
    NSNumber *factor = [factores objectForKey:tipoActividad];
    
    if (factor) {
        return [factor floatValue] * cantidad;
    }
    
    return 0.0; // Si no se encuentra el tipo de actividad
}

#pragma mark - Métodos Auxiliares

- (HabitoSostenible *)habitoFromStatement:(sqlite3_stmt *)statement {
    HabitoSostenible *habito = [[HabitoSostenible alloc] init];
    
    habito.habitoId = sqlite3_column_int(statement, 0);
    habito.categoria = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
    habito.actividad = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
    habito.cantidadCO2Ahorrado = sqlite3_column_double(statement, 3);
    
    const char *fechaStr = (const char *)sqlite3_column_text(statement, 4);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    habito.fecha = [formatter dateFromString:[NSString stringWithUTF8String:fechaStr]];
    
    const char *notasStr = (const char *)sqlite3_column_text(statement, 5);
    habito.notas = notasStr ? [NSString stringWithUTF8String:notasStr] : @"";
    
    return habito;
}

- (DesafioEcologico *)desafioFromStatement:(sqlite3_stmt *)statement {
    DesafioEcologico *desafio = [[DesafioEcologico alloc] init];
    
    desafio.desafioId = sqlite3_column_int(statement, 0);
    desafio.titulo = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
    
    const char *descStr = (const char *)sqlite3_column_text(statement, 2);
    desafio.descripcion = descStr ? [NSString stringWithUTF8String:descStr] : @"";
    
    desafio.duracionDias = sqlite3_column_int(statement, 3);
    desafio.progresoActual = sqlite3_column_int(statement, 4);
    desafio.completado = sqlite3_column_int(statement, 5) == 1;
    
    const char *fechaStr = (const char *)sqlite3_column_text(statement, 6);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    desafio.fechaInicio = [formatter dateFromString:[NSString stringWithUTF8String:fechaStr]];
    
    desafio.recompensaPuntos = sqlite3_column_double(statement, 7);
    
    return desafio;
}

- (void)actualizarEstadisticasDia:(NSDate *)fecha conCO2:(float)co2 {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *fechaString = [formatter stringFromDate:fecha];
    
    const char *sql = "INSERT INTO estadisticas_diarias (fecha, total_co2_ahorrado, numero_actividades, racha) "
                      "VALUES (?, ?, 1, 1) "
                      "ON CONFLICT(fecha) DO UPDATE SET "
                      "total_co2_ahorrado = total_co2_ahorrado + ?, "
                      "numero_actividades = numero_actividades + 1";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(statement, 2, co2);
        sqlite3_bind_double(statement, 3, co2);
        
        sqlite3_step(statement);
    }
    
    sqlite3_finalize(statement);
}

- (void)dealloc {
    [self closeDatabase];
}

@end
