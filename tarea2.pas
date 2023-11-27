function hash ( semilla, paso, N : Natural; p : Palabra ) : Natural;
var
    i : Integer; 
    acumulador : Natural;
begin
    acumulador := semilla;
    { Itera a través de los caracteres de la palabra,
        actualizando el acumulador con el algoritmo de hash }
    for i := 1 to p.tope do 
        begin
            acumulador := (acumulador * paso + Ord(p.cadena[i])) mod N;
        end;
    hash := acumulador;
end;

function comparaPalabra ( p1, p2 : Palabra ) : Comparacion;
var
  i: Integer;
begin
    i := 1;
    // Compara las cadenas de dos palabras, devuelve Igual si son idénticas, Menor si p1 es menor, y Mayor si p1 es mayor
    while (i <= p1.tope) and (i <= p2.tope) and (p1.cadena[i] = p2.cadena[i]) do
    i := i + 1;

    if (i > p1.tope) and (i > p2.tope) then
        comparaPalabra := Igual 
    else if (i > p1.tope) or ((i <= p2.tope) and (p1.cadena[i] < p2.cadena[i])) then
        comparaPalabra := Menor
    else
        comparaPalabra := Mayor; 
end;

function mayorPalabraCant( pc1, pc2 : PalabraCant ) : boolean;
begin
    // Compara las cantidades y las palabras, devuelve true si pc1 es mayor que pc2, false de lo contrario
    if (pc1.cant > pc2.cant) or ((pc1.cant = pc2.cant) and (comparaPalabra(pc1.pal, pc2.pal) = Mayor)) then
      mayorPalabraCant := true
    else
      mayorPalabraCant := false;
end;

procedure agregarOcurrencia( p: Palabra; var pals: Ocurrencias );
var
  nuevaOcurrencia, actual, anterior: Ocurrencias;
begin
  nuevaOcurrencia := nil;
  actual := pals;
  anterior := nil;

  // Busca si la palabra ya está en la lista 
  while (actual <> nil) and (comparaPalabra(actual^.palc.pal, p) <> Igual) do
  begin
    anterior := actual;
    actual := actual^.sig;
  end;

  // Contempla el caso en el que la palabra NO está en la lista
  if actual = nil then
  begin
    new(nuevaOcurrencia);
    nuevaOcurrencia^.palc.pal := p;
    nuevaOcurrencia^.palc.cant := 1;
    nuevaOcurrencia^.sig := nil;

    if anterior = nil then
      pals := nuevaOcurrencia
    else
      anterior^.sig := nuevaOcurrencia;
  end
  else
  begin
    // Contempla el caso en el que la palabra SI está en la lista 
    actual^.palc.cant := actual^.palc.cant + 1;
  end;
end;


procedure inicializarPredictor( var pred: Predictor );
var
  i: integer;
begin 
  // Inicializa cada lista de ocurrencias como vacía
  for i := 1 to MAXHASH do
    pred[i] := nil;  
end;


procedure entrenarPredictor ( txt : Texto; var pred: Predictor );
var
  actual, siguiente: Texto;
  hashActual: Natural;
begin
  actual := txt;

  // Iteraa sobre la lista de palabras 
  while (actual <> nil) and (actual^.sig <> nil) do
  begin
    siguiente := actual^.sig;

    // Obtiene el codigo hash de la palabra actual
    hashActual := hash(SEMILLA, PASO, MAXHASH, actual^.info);

    // Agrega la ocurrencia de la siguiente palabra en el predictor
    agregarOcurrencia(siguiente^.info, pred[hashActual]);

    // Avanza a la siguiente palabra en el texto 
    actual := siguiente;
  end;
end;
 
procedure insOrdAlternativas( pc: PalabraCant; var alts: Alternativas );
var
   i: Integer;
   temp: PalabraCant;
begin
   // Inserta la palabra con su cantidad en la lista de alternativas en orden
   if alts.tope < MAXALTS then
   begin
      alts.tope := alts.tope + 1;
      alts.pals[alts.tope] := pc;
   end
   else
   begin
      // Reemplaza la última alternativa solo si pc es mayor
      if mayorPalabraCant(pc, alts.pals[MAXALTS]) then
         alts.pals[MAXALTS] := pc;
   end;

   // Intercambia hacia la posición correcta en la lista
   i := alts.tope;
   while (i > 1) and (mayorPalabraCant(alts.pals[i], alts.pals[i - 1])) do
   begin
      temp := alts.pals[i];
      alts.pals[i] := alts.pals[i - 1];
      alts.pals[i - 1] := temp;

      i := i - 1;
   end;
end;

procedure obtenerAlternativas( p: Palabra; pred: Predictor; var alts: Alternativas );
var
  hashP: Natural;
  ocurrenciasP: Ocurrencias;
  pc: PalabraCant;
begin
  // Calcula el código hash de la palabra p
  hashP := hash(SEMILLA, PASO, MAXHASH, p);

  // Obtiene la lista de ocurrencias de palabras que suelen seguir a p
  ocurrenciasP := pred[hashP];
  
  alts.tope := 0;

  // Itera sobre la lista de ocurrenciasP e inserta las alternativas en alts
  while (ocurrenciasP <> nil) do
  begin
    pc := ocurrenciasP^.palc;

    // Inserta la alternativa ordenadamente en alts
    insOrdAlternativas(pc, alts);

    // Avanza a la siguiente ocurrencia en la lista
    ocurrenciasP := ocurrenciasP^.sig;
  end;
end;