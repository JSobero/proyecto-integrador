from fastapi import APIRouter, HTTPException
import httpx

router = APIRouter(tags=["IA y Procesamiento ARASAAC"])
cache_pictogramas = {}

@router.get("/pictogramas/generar/{palabra}")
async def generar_pictograma_jit(palabra: str):
    palabra_busqueda = palabra.lower().strip()
    if palabra_busqueda in cache_pictogramas:
        return cache_pictogramas[palabra_busqueda]
        
    url = f"https://api.arasaac.org/api/pictograms/es/bestsearch/{palabra_busqueda}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code == 200 and response.json():
            data = response.json()
            picto_id = data[0]['_id']
            image_url = f"https://static.arasaac.org/pictograms/{picto_id}/{picto_id}_300.png"
            resultado = {"palabra": palabra_busqueda.upper(), "url": image_url}
            cache_pictogramas[palabra_busqueda] = resultado
            return resultado
            
    raise HTTPException(status_code=404, detail="No se encontró un pictograma")

@router.get("/frases/conjugar/{frase}")
async def conjugar_frase(frase: str):
    url = f"https://api.arasaac.org/api/phrases/flex/es/{frase}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code == 200:
            return response.json()
    return {"msg": frase}