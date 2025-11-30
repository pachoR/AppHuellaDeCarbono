#import "DatabaseManager.h"

@implementation Actividad
@end

@implementation Desafio
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
        "cantidad FLOAT);";
    
    const char *sqlDesafio =
    "CREATE TABLE IF NOT EXISTS desafio ("
    "desafio_id INTEGER PRIMARY KEY AUTOINCREMENT, "
    "desafio_uno TEXT, "
    "desafio_dos TEXT, "
    "fecha_creacion DATE DEFAULT CURRENT_DATE);";

    char *errorMsg;
    
    if (sqlite3_exec(_database, sqlActividad, NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSLog(@"Error creando tabla actividad: %s", errorMsg);
        sqlite3_free(errorMsg);
    }
    
    if (sqlite3_exec(_database, sqlDesafio, NULL, NULL, &errorMsg) != SQLITE_OK) {
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
    sqlite3_bind_double(statement, 3, actividad.cantidad);
    
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
    sqlite3_bind_double(statement, 3, actividad.cantidad);
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
    actividad.cantidad = sqlite3_column_double(statement, 3);
    
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

- (NSArray<Actividad *> *)getActividadesHoy {
    NSMutableArray *actividades = [NSMutableArray array];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *hoyString = [formatter stringFromDate:[NSDate date]];
    
    const char *sql = "SELECT * FROM actividad WHERE fecha = ? ORDER BY actividad_id DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [hoyString UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Actividad *actividad = [self actividadFromStatement:statement];
            [actividades addObject:actividad];
        }
    }
    
    sqlite3_finalize(statement);
    return actividades;
}

#pragma mark - Racha
- (NSInteger)getRachaCount {
    NSInteger racha = 0;
    NSDate *fechaActual = [NSDate date];
    NSDateComponents *componentes = [[NSDateComponents alloc] init];
    NSCalendar *calendario = [NSCalendar currentCalendar];
    
    // Verificar días consecutivos hacia atrás
    for (NSInteger diasAtras = 0; diasAtras < 365; diasAtras++) { // Límite de 1 año
        [componentes setDay:-diasAtras];
        NSDate *fechaVerificar = [calendario dateByAddingComponents:componentes toDate:fechaActual options:0];
        
        NSArray<Actividad *> *actividadesDelDia = [self getActividadesByFecha:fechaVerificar];
        
        if (actividadesDelDia.count > 0) {
            racha++;
        } else {
            break;
        }
    }
    
    return racha;
}

#pragma mark - CRUD Desafios

- (BOOL)insertDesafio:(Desafio *)desafio {
    const char *sql = "INSERT INTO desafio (desafio_uno, desafio_dos) VALUES (?, ?)";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"Error preparando insert desafio: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    sqlite3_bind_text(statement, 1, [desafio.desafioUno UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, [desafio.desafioDos UTF8String], -1, SQLITE_TRANSIENT);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    
    if (success) {
        desafio.desafioId = sqlite3_last_insert_rowid(_database);
    }
    
    sqlite3_finalize(statement);
    return success;
}

- (Desafio *)getDesafioActual {
    const char *sql = "SELECT * FROM desafio ORDER BY fecha_creacion DESC LIMIT 1";
    sqlite3_stmt *statement;
    
    Desafio *desafio = nil;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            desafio = [self desafioFromStatement:statement];
        }
    }
    
    sqlite3_finalize(statement);
    return desafio;
}

- (NSArray<Desafio *> *)getAllDesafios {
    NSMutableArray *desafios = [NSMutableArray array];
    
    const char *sql = "SELECT * FROM desafio ORDER BY fecha_creacion DESC";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Desafio *desafio = [self desafioFromStatement:statement];
            [desafios addObject:desafio];
        }
    }
    
    sqlite3_finalize(statement);
    return desafios;
}

- (BOOL)updateDesafio:(Desafio *)desafio {
    const char *sql = "UPDATE desafio SET desafio_uno = ?, desafio_dos = ? WHERE desafio_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"Error preparando update desafio: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    sqlite3_bind_text(statement, 1, [desafio.desafioUno UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, [desafio.desafioDos UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 3, (int)desafio.desafioId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (BOOL)deleteDesafio:(NSInteger)desafioId {
    const char *sql = "DELETE FROM desafio WHERE desafio_id = ?";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"Error preparando delete desafio: %s", sqlite3_errmsg(_database));
        return NO;
    }
    
    sqlite3_bind_int(statement, 1, (int)desafioId);
    
    BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
    sqlite3_finalize(statement);
    
    return success;
}

- (Desafio *)desafioFromStatement:(sqlite3_stmt *)statement {
    Desafio *desafio = [[Desafio alloc] init];
    
    desafio.desafioId = sqlite3_column_int(statement, 0);
    
    if (sqlite3_column_text(statement, 1) != NULL) {
        desafio.desafioUno = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
    } else {
        desafio.desafioUno = @"";
    }
    
    if (sqlite3_column_text(statement, 2) != NULL) {
        desafio.desafioDos = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
    } else {
        desafio.desafioDos = @"";
    }
    
    if (sqlite3_column_text(statement, 3) != NULL) {
        const char *fechaStr = (const char *)sqlite3_column_text(statement, 3);
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        desafio.fechaCreacion = [formatter dateFromString:[NSString stringWithUTF8String:fechaStr]];
    }
    
    return desafio;
}

- (BOOL)saveDesafiosDiarios:(NSString *)desafioUno desafioDos:(NSString *)desafioDos {
    Desafio *desafioHoy = [self getDesafioActual];
    
    if (desafioHoy) {
        desafioHoy.desafioUno = desafioUno;
        desafioHoy.desafioDos = desafioDos;
        return [self updateDesafio:desafioHoy];
    } else {
        Desafio *nuevoDesafio = [[Desafio alloc] init];
        nuevoDesafio.desafioUno = desafioUno;
        nuevoDesafio.desafioDos = desafioDos;
        return [self insertDesafio:nuevoDesafio];
    }
}

#pragma mark - Datos para Gráficos

- (NSDictionary *)getDatosSemanalesCO2 {
    NSMutableDictionary *datosSemanales = [NSMutableDictionary dictionary];
    
    NSCalendar *calendario = [NSCalendar currentCalendar];
    NSDate *hoy = [NSDate date];
    
    NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
    [displayFormatter setDateFormat:@"EEE dd"];
    [displayFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"es_ES"]];
    
    // Obtener las fechas de la semana (SOLO 7 DÍAS ATRÁS)
    NSMutableArray *fechasSemana = [NSMutableArray array];
    for (int i = 6; i >= 0; i--) {
        NSDateComponents *componentes = [[NSDateComponents alloc] init];
        [componentes setDay:-i]; // Solo días pasados
        NSDate *fecha = [calendario dateByAddingComponents:componentes toDate:hoy options:0];
        [fechasSemana addObject:fecha];
        
        // Inicializar con 0
        NSString *fechaDisplay = [displayFormatter stringFromDate:fecha];
        datosSemanales[fechaDisplay] = @(0.0);
    }
    
    // Consulta: suma total por día (cantidad real)
    const char *sql = "SELECT fecha, SUM(cantidad) as total_cantidad FROM actividad WHERE fecha <= date('now') AND fecha >= date('now', '-6 days') GROUP BY fecha ORDER BY fecha";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const char *fechaStr = (const char *)sqlite3_column_text(statement, 0);
            float totalCantidad = sqlite3_column_double(statement, 1);
            
            NSString *fechaDB = [NSString stringWithUTF8String:fechaStr];
            
            // Convertir fecha de la BD a NSDate
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSDate *fecha = [formatter dateFromString:fechaDB];
            NSString *fechaDisplay = [displayFormatter stringFromDate:fecha];
            
            // Actualizar el valor para este día
            datosSemanales[fechaDisplay] = @(totalCantidad);
        }
    }
    
    sqlite3_finalize(statement);
    return datosSemanales;
}

- (NSDictionary *)getDatosMensualesCO2 {
    NSMutableDictionary *datosMensuales = [NSMutableDictionary dictionary];
    
    NSCalendar *calendario = [NSCalendar currentCalendar];
    NSDate *hoy = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
    [displayFormatter setDateFormat:@"MMM"];
    [displayFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"es_ES"]];
    
    // Para cada mes de los últimos 6 meses (SOLO PASADO)
    for (int i = 5; i >= 0; i--) {
        NSDateComponents *componentes = [[NSDateComponents alloc] init];
        [componentes setMonth:-i];
        NSDate *fechaMes = [calendario dateByAddingComponents:componentes toDate:hoy options:0];
        
        // Si la fecha resultante es en el futuro, saltar
        if ([fechaMes compare:hoy] == NSOrderedDescending) {
            continue;
        }
        
        NSString *mesDisplay = [[displayFormatter stringFromDate:fechaMes] capitalizedString];
        
        // Obtener primer y último día del mes
        NSRange rango = [calendario rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:fechaMes];
        NSDateComponents *compInicio = [calendario components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:fechaMes];
        compInicio.day = 1;
        NSDate *primerDia = [calendario dateFromComponents:compInicio];
        
        compInicio.day = rango.length;
        NSDate *ultimoDia = [calendario dateFromComponents:compInicio];
        
        // Asegurar que no incluimos días futuros
        if ([ultimoDia compare:hoy] == NSOrderedDescending) {
            ultimoDia = hoy;
        }
        
        // Consulta para cantidad total del mes
        const char *sql = "SELECT SUM(cantidad) as total_cantidad FROM actividad WHERE fecha BETWEEN ? AND ?";
        sqlite3_stmt *statement;
        
        float totalCantidadMes = 0.0;
        
        if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
            NSString *inicioString = [formatter stringFromDate:primerDia];
            NSString *finString = [formatter stringFromDate:ultimoDia];
            
            sqlite3_bind_text(statement, 1, [inicioString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [finString UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                totalCantidadMes = sqlite3_column_double(statement, 0);
            }
        }
        
        sqlite3_finalize(statement);
        datosMensuales[mesDisplay] = @(totalCantidadMes);
    }
    
    return datosMensuales;
}
@end
