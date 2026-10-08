from fastapi import APIRouter, HTTPException
import httpx
import spacy

router = APIRouter(tags=["IA y Procesamiento ARASAAC"])
cache_pictogramas = {}

# --- MOTOR DE PROCESAMIENTO DE LENGUAJE NATURAL (NLP) ---
# Cargamos el modelo de español en memoria al arrancar el servidor
try:
    nlp = spacy.load("es_core_news_sm")
except OSError:
    print("ADVERTENCIA: No se encontró el modelo 'es_core_news_sm'. Ejecuta: python -m spacy download es_core_news_sm")
    nlp = None

@router.get("/pictogramas/generar/{palabra}")
async def generar_pictograma_jit(palabra: str):
    palabra_original = palabra.lower().strip()
    palabra_busqueda = palabra_original
    
    # 1. LEMATIZACIÓN INTELIGENTE CON IA (Sustituye al diccionario manual)
    # Ejemplo: "amo" -> "amar", "perros" -> "perro", "fui" -> "ir"
    if nlp is not None:
        doc = nlp(palabra_original)
        if len(doc) > 0:
            # Extraemos el lema (la raíz de la palabra)
            lema = doc[0].lemma_
            # Evitamos lematizar palabras muy cortas que puedan confundir a la IA (como "te", "la", "el")
            if len(palabra_original) > 2:
                palabra_busqueda = lema

    # 2. Verificamos la caché
    if palabra_busqueda in cache_pictogramas:
        return {"palabra": palabra_original.upper(), "url": cache_pictogramas[palabra_busqueda]["url"]}
        
    url_best = f"https://api.arasaac.org/api/pictograms/es/bestsearch/{palabra_busqueda}"
    url_search = f"https://api.arasaac.org/api/pictograms/es/search/{palabra_busqueda}"
    
    async with httpx.AsyncClient(timeout=20.0) as client:
        try:
            # 3. Primer Intento: Búsqueda Exacta con el Lema
            response = await client.get(url_best)
            if response.status_code == 200 and response.json():
                data = response.json()
                picto_id = data[0]['_id']
                image_url = f"https://static.arasaac.org/pictograms/{picto_id}/{picto_id}_300.png"
                
                cache_pictogramas[palabra_busqueda] = {"url": image_url}
                return {"palabra": palabra_original.upper(), "url": image_url}
            
            # 4. Segundo Intento: Búsqueda Flexible 
            response_search = await client.get(url_search)
            if response_search.status_code == 200 and response_search.json():
                 data = response_search.json()
                 picto_id = data[0]['_id']
                 image_url = f"https://static.arasaac.org/pictograms/{picto_id}/{picto_id}_300.png"
                 
                 cache_pictogramas[palabra_busqueda] = {"url": image_url}
                 return {"palabra": palabra_original.upper(), "url": image_url}

        except httpx.ReadTimeout:
            raise HTTPException(status_code=504, detail="El servidor de ARASAAC tardó demasiado")
        except httpx.ConnectTimeout:
            raise HTTPException(status_code=503, detail="No se pudo establecer conexión con ARASAAC")
            
    raise HTTPException(status_code=404, detail="No se encontró un pictograma")

@router.get("/frases/conjugar/{frase}")
async def conjugar_frase(frase: str):
    url = f"https://api.arasaac.org/api/phrases/flex/es/{frase}"
    
    async with httpx.AsyncClient(timeout=20.0) as client:
        try:
            response = await client.get(url)
            if response.status_code == 200:
                return response.json()
        except Exception:
            return {"msg": frase}
            
    return {"msg": frase}