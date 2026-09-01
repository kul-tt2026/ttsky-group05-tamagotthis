from PIL import Image

img = Image.open("hart.png")

print(img.mode)



print(img.getpixel((0, 0)))
print(img.getpixel((17, 10)))
print(img.getpixel((15, 14)))

#print(img.load())
#print(list(img.get_flattened_data()))

kleur_naar_nummer = {
    (0, 0, 0, 0): 0,                # transparant
    (0, 0, 0, 255): 1,              # zwart
    (255, 255, 255, 255): 2,        # wit
    (251, 0, 0, 255): 3 ,          # rood
}

#for x in range(0,32):
#    for y in range(0,32):
#        kleur = img.getpixel((x,y))
#        nummer = kleur_naar_nummer[kleur]
#        print(nummer)

grid = []
for y in range(0,32):
    rij = []
    for x in range(0,32):
        kleur = img.getpixel((x,y))
        nummer = kleur_naar_nummer[kleur]
        rij.append(nummer)
    grid.append(rij)

#print(grid)


with open("hart1.hex", "w") as f:         
    # w = write betekent dat het oude bestand verdwijnt , maakt anders nieuw bestand aan of scrijft over oude
    for rij in grid:
        for nummer in rij:
            f.write(str(nummer) + "\n")

with open("hart1.hex", "w") as f:  
    grid = []
    for y in range(0,32):
        rij = []
        for x in range(0,32):
            kleur = img.getpixel((x,y))
            nummer = kleur_naar_nummer[kleur]
            rij.append(nummer)

        grid.append(rij)
        # nummers omzetten naar strings, dan samenvoegen met spaties ertussen
        rij_tekst = " ".join(str(n) for n in rij)
        f.write(rij_tekst + "\n")
    


