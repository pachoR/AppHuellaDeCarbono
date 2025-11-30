#import "DatabaseManager.h"

@implementation Actividad
@end

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
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _databasePath = [documentsDirectory stringByAppendingPathComponent:@"ecohuella.db"];
        NSLog(@"Database path: %@", _databasePath);
    }
    return self;
}

#pragma mark - Inicialización de Base de Datos

- (BOOL)initializeDatabase {
    if (sqlite3_open([self.databasePath UTF8String], &_database) != SQLITE_OK) {
        NSLog(@"Error al abrir base de datos: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    [self createTables];
    return YES;
}

- (void)createTables {
    const char *sqlActividad =
        "CREATE TABLE IF NOT EXISTS actividad ("
        "actividad_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "fecha DATE, "
        "tipoAct TEXT, "
        "cantidad INTEGER);";

    char *errorMsg;
    
    if (sqlite3_exec(_database, sqlActividad, NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSLog(@"Error creando tabla actividad: %s", errorMsg);
        sqlite3_free(errorMsg);
    }
    
    NSLog(@"Tabla actividad creada exitosamente");
}

- (void)closeDatabase {
    if (_database) {
        sqlite3_close(_database);
        _database = nil;
    }
}

#pragma mark - CRUD Actividad

- (BOOL)insertActividad:(Actividad *)actividad {
    const char *sql = "INSERT INTO actividad (fecha, tipoAct, cantidad) VALUES (?, ?, ?)";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"Error preparando insert actividad: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *fechaString = [formatter stringFromDate:actividad.fecha];
    sqlite3_bind_text(statement, 1, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(statement, 2, [actividad.tipoAct UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 3, (int)actividad.cantidad);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    
    if (success) {
        actividad.actividadId = sqlite3_last_insert_rowid(_database);
    }
    
    sqlite3_finalize(statement);
    return success;
}

- (NSArray<Actividad *> *)getAllActividades {
    NSMutableArray *actividades = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM actividad ORDER BY fecha DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Actividad *actividad = [self actividadFromStatement:statement];
            [actividades addObject:actividad];
        }
    }
    
    sqlite3_finalize(statement);
    return actividades;
}

- (NSArray<Actividad *> *)getActividadesByTipo:(NSString *)tipo {
    NSMutableArray *actividades = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM actividad WHERE tipoAct = ? ORDER BY fecha DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [tipo UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Actividad *actividad = [self actividadFromStatement:statement];
            [actividades addObject:actividad];
        }
    }
    
    sqlite3_finalize(statement);
    return actividades;
}

- (NSArray<Actividad *> *)getActividadesByFecha:(NSDate *)fecha {
    NSMutableArray *actividades = [NSMutableArray array];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *fechaString = [formatter stringFromDate:fecha];
    
    const char *sql = "SELECT * FROM actividad WHERE fecha = ? ORDER BY actividad_id DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Actividad *actividad = [self actividadFromStatement:statement];
            [actividades addObject:actividad];
        }
    }
    
    sqlite3_finalize(statement);
    return actividades;
}

- (BOOL)updateActividad:(Actividad *)actividad {
    const char *sql = "UPDATE actividad SET fecha = ?, tipoAct = ?, cantidad = ? WHERE actividad_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *fechaString = [formatter stringFromDate:actividad.fecha];
    sqlite3_bind_text(statement, 1, [fechaString UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(statement, 2, [actividad.tipoAct UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 3, (int)actividad.cantidad);
    sqlite3_bind_int(statement, 4, (int)actividad.actividadId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (BOOL)deleteActividad:(NSInteger)actividadId {
    const char *sql = "DELETE FROM actividad WHERE actividad_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        return NO;
    }
    
    sqlite3_bind_int(statement, 1, (int)actividadId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (Actividad *)actividadFromStatement:(sqlite3_stmt *)statement {
    Actividad *actividad = [[Actividad alloc] init];
    
    actividad.actividadId = sqlite3_column_int(statement, 0);
    
    const char *fechaStr = (const char *)sqlite3_column_text(statement, 1);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    actividad.fecha = [formatter dateFromString:[NSString stringWithUTF8String:fechaStr]];
    
    actividad.tipoAct = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
    actividad.cantidad = sqlite3_column_int(statement, 3);
    
    return actividad;
}

#pragma mark - Cálculo de CO2

- (float)calcularCO2ParaActividad:(NSString *)tipoActividad cantidad:(float)cantidad {
    NSDictionary *factoresCO2 = @{
        @"transporte": @(0.18),    // 0.18 kg CO2 por km
        @"energia": @(0.25),       // 0.25 kg CO2 por kWh
        @"alimentacion": @(1.0)    // 1.0 kg CO2 por kg
    };
    
    NSNumber *factor = factoresCO2[tipoActividad];
    if (factor) {
        return [factor floatValue] * cantidad;
    }
    
    return 0.0;
}

- (void)dealloc {
    [self closeDatabase];
}

@end
