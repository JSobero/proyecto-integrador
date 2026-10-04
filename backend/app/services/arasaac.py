# Ruta: backend/app/services/arasaac.py
import httpx

async def buscar_pictograma_arasaac(palabra: str):
    # Endpoint oficial de búsqueda en español de ARASAAC
    url = f"https://api.arasaac.org/api/pictograms/es/search/{palabra.lower()}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url)
            if response.status_code == 200:
                data = response.json()
                if data and len(data) > 0:
                    # Extraemos el ID del primer resultado exacto
                    pic_id = data[0]["_id"]
                    # Retornamos la URL estática de la imagen en alta calidad (300px)
                    return f"https://static.arasaac.org/pictograms/{pic_id}/{pic_id}_300.png"
        except Exception as e:
            print(f"Error conectando a ARASAAC: {e}")
            
    # Si no encuentra la palabra, retorna None (el frontend mostrará un cuadro con texto)
    return None