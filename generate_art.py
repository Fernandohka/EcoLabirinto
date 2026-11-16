"""EcoLabirinto: sprites autorais simples em pixel art, gerados localmente com Pillow.
A arte não usa/recorta as imagens de referência fornecidas pelo usuário.
Execute: python generate_art.py (Pillow requerido apenas para regenerar a arte).
O jogo Godot utiliza somente os PNGs gerados.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import random, math
ROOT=Path(__file__).parent/'Assets'

def make(rel, size, draw):
 p=ROOT/rel; p.parent.mkdir(parents=True,exist_ok=True)
 im=Image.new('RGBA',(size,size),(0,0,0,0)); d=ImageDraw.Draw(im)
 draw(d,im); im.save(p)

def ellipse(d,xy,c,edge='#283027',w=2):
 d.ellipse(xy,fill=c,outline=edge,width=w)
def rect(d,xy,c):d.rectangle(xy,fill=c)
def line(d,pts,c,w=1):d.line(pts,fill=c,width=w,joint='curve')

# Pixel-art animals with varied distinctive silhouettes. Original art.
def creature(name,body,belly,ear=None,kind='mammal'):
 def render(d,im):
  outline='#322d2b'; dark='#433c34'
  d.ellipse((5,34,43,44), fill=(15,25,25,45))
  if kind=='bird':
   ellipse(d,(8,9,38,40),body,outline,2)
   ellipse(d,(14,20,34,38),belly,body,1)
   d.polygon([(14,10),(10,3),(22,11)],fill=body)
   d.polygon([(33,11),(37,4),(35,19)],fill=body)
   rect(d,(15,16,18,19),outline);rect(d,(29,16,32,19),outline)
   d.polygon([(20,20),(40,24),(22,30)], fill='#f4ba49' if name not in ['tucano'] else '#e8ae40')
   if name=='tucano':
    d.polygon([(25,21),(46,19),(45,27),(25,31)],fill='#f5b74c');rect(d,(39,23,45,25),'#4d3a2b')
   else:
    d.polygon([(2,18),(10,22),(12,35)],fill='#55b7de')
  elif kind=='reptile':
   d.polygon([(3,26),(14,19),(38,19),(45,29),(35,36),(6,34)],fill=body)
   ellipse(d,(5,14,41,36),body,outline,2)
   ellipse(d,(13,25,34,37),belly,outline,1)
   ellipse(d,(9,12,18,22),body,outline,2);ellipse(d,(29,12,38,22),body,outline,2)
   rect(d,(13,17,15,20),outline);rect(d,(32,17,34,20),outline)
  elif kind=='frog':
   ellipse(d,(4,18,44,41),body,outline,2)
   ellipse(d,(12,26,37,40),belly,body,1)
   ellipse(d,(7,10,22,26),body,outline,2);ellipse(d,(26,10,41,26),body,outline,2)
   rect(d,(13,15,16,19),outline);rect(d,(32,15,35,19),outline)
   line(d,[(18,30),(25,32),(31,30)],'#667742',1)
   ellipse(d,(3,35,14,43),body,outline,2);ellipse(d,(34,35,45,43),body,outline,2)
  else:
   # Body with belly, little paws and face
   ellipse(d,(6,15,42,41),body,outline,2)
   ellipse(d,(15,24,36,39),belly,body,1)
   ellipse(d,(6,12,21,29),body,outline,2);ellipse(d,(24,12,39,29),body,outline,2)
   if kind=='cat':
    d.polygon([(8,18),(12,7),(21,18)],fill=body);d.polygon([(27,17),(36,7),(39,21)],fill=body)
    d.polygon([(12,17),(14,11),(19,18)],fill='#edb98a');d.polygon([(29,16),(34,10),(35,19)],fill='#edb98a')
   elif kind=='anteater':
    d.polygon([(16,20),(3,28),(10,33),(27,28)],fill=belly)
   else:
    ellipse(d,(9,10,19,22),ear or body,outline,2);ellipse(d,(30,10,40,22),ear or body,outline,2)
   rect(d,(14,21,17,24),outline);rect(d,(30,21,33,24),outline)
   ellipse(d,(19,28,29,33),belly,outline,1)
   rect(d,(22,28,25,30),outline)
   ellipse(d,(8,35,17,43),body,outline,2);ellipse(d,(31,35,40,43),body,outline,2)
  if name=='onca':
   for x,y in [(9,30),(35,30),(11,24),(37,24),(20,38),(29,35)]:rect(d,(x,y,x+3,y+3),'#62482c')
  if name=='tatu':
   for x in (18,25,32):line(d,[(x,17),(x+3,26),(x,35)],'#897452',2)
  if name=='mico':
   ellipse(d,(3,15,13,30),'#f6cf77','#5f3d2b',1);ellipse(d,(35,15,45,30),'#f6cf77','#5f3d2b',1)
  if name=='capivara':
   rect(d,(3,25,12,32),'#9a673e'); rect(d,(12,16,18,18),'#a8784b')
  if name=='lobo_guara':
   rect(d,(10,36,12,43),'#423027');rect(d,(35,36,37,43),'#423027')
  if name=='peixe_boi':
   ellipse(d,(6,13,41,40),'#888f94','#40484c',2)
   ellipse(d,(12,22,34,37),'#afb9b8','#888f94',1)
   ellipse(d,(11,10,22,18),'#888f94','#40484c',1)
   ellipse(d,(29,10,40,18),'#888f94','#40484c',1)
 make('Animals/Mission/'+name+'.png',48,render)

animals={
 'capivara':('#b98d61','#d8b68a',None,'mammal'),
 'sapo':('#78b653','#bde28a',None,'frog'),
 'tatu':('#a38a66','#ceb899',None,'mammal'),
 'arara':('#df5559','#f3af4b',None,'bird'),
 'jacare':('#598b55','#a5b978',None,'reptile'),
 'macaco':('#a06d4a','#e6bd90',None,'mammal'),
 'preguica':('#a69d82','#e5d6bb',None,'mammal'),
 'tamandua':('#8c9189','#e2d3b8',None,'anteater'),
 'lobo_guara':('#cf8049','#f6d39b',None,'cat'),
 'tuiuiu':('#faf5e5','#ffffff',None,'bird'),
 'onca':('#e9b44c','#f9d889',None,'cat'),
 'mico':('#f4af43','#f8d379',None,'mammal'),
 'tucano':('#333e49','#eee1ae',None,'bird'),
 'quati':('#a78a62','#e4cda0',None,'mammal'),
 'peixe_boi':('#808c8c','#c5cfcd',None,'reptile'),
}
for n,pars in animals.items():creature(n,*pars)

# Secret variants are fully original, never downloaded images.
for name,base,extra in [
 ('sapo_chapeu','sapo','hat'),('capivara_oculos','capivara','glasses'),('tatu_dourado','tatu','gold'),('sapo_azul','sapo','blue')]:
 im=Image.open(ROOT/'Animals/Mission'/f'{base}.png').copy(); d=ImageDraw.Draw(im)
 if extra=='hat':
  rect(d,(12,7,37,11),'#46312a');rect(d,(18,2,31,9),'#624436');rect(d,(17,7,32,8),'#e4b168')
 elif extra=='glasses':
  d.rectangle((9,19,19,26),outline='#233441',width=2);d.rectangle((27,19,37,26),outline='#233441',width=2);rect(d,(19,22,27,23),'#233441')
 elif extra=='gold':
  from PIL import ImageEnhance
  im=ImageEnhance.Color(im).enhance(2.0);d=ImageDraw.Draw(im)
  for i in range(4):rect(d,(3+i*10,5+(i%2)*5,5+i*10,7+(i%2)*5),'#ffe48e')
 else: im=Image.open(ROOT/'Animals/Mission/sapo.png').copy(); px=im.load()
 # blue tint after frog drawing
 if extra=='blue':
  for y in range(im.height):
   for x in range(im.width):
    r,g,b,a=px[x,y]
    if a and g>r*1.15 and g>b*1.08: px[x,y]=(int(b*0.75),int(g*0.86),min(255,g+50),a)
 p=ROOT/'Animals/Memes'/f'{name}.png';p.parent.mkdir(parents=True,exist_ok=True);im.save(p)

# Trees/vegetation; art on 48x48 canvases, 4 biomes x 3 variants.
def tree(biome,variant):
 colors={
 'Amazonia':[('#2d633d','#478a45','#7fb257'),('#265d4b','#39866c','#82b17e'),('#35683f','#598a45','#a2bf64')],
 'Cerrado':[('#567147','#89964e','#c3b768'),('#5d6335','#a09245','#cec17a'),('#6e833d','#a5b85d','#d9cb72')],
 'Pantanal':[('#2f735c','#4c9875','#89b996'),('#327d66','#3d947c','#91baa1'),('#427d4f','#6da363','#b1c181')],
 'MataAtlantica':[('#22543e','#2d7956','#69ac76'),('#1e5e58','#358f78','#85bfa3'),('#2a6245','#478c62','#9dc88b')],
 'Boss':[('#422929','#85432e','#ec713e'),('#482d2b','#a64f31','#f3a44f'),('#47322f','#7c3a35','#e87e40')]
 }
 c1,c2,c3=colors[biome][variant]
 def render(d,im):
  d.ellipse((5,39,44,47),fill=(8,20,12,70))
  rect(d,(21,21,27,43),'#58402e')
  rect(d,(23,22,24,42),'#946e47')
  if biome=='Cerrado':
   line(d,[(23,29),(14,20),(9,13)],'#6c5137',3);line(d,[(26,29),(34,16),(39,12)],'#6c5137',3)
   for x,y,r in [(11,14,10),(30,11,10),(22,9,10)]: ellipse(d,(x-r,y-r,x+r,y+r),c2,c1,2)
  elif biome=='Pantanal' and variant==1:
   for x in (12,18,31,38):line(d,[(24,16),(x,37)],c2,3)
   ellipse(d,(9,5,41,24),c2,c1,2)
  elif biome=='Amazonia' and variant==2:
   # Palmeira / açaizeiro
   for a in range(-3,4):
    px=23+a*5; py=9+abs(a)*4
    line(d,[(24,14),(px,py)],c1,4); line(d,[(23,13),(px,py)],c2,2)
   rect(d,(21,20,27,45),'#6d4e37')
  elif biome=='MataAtlantica' and variant==1:
   for x in [11,19,28,37]:ellipse(d,(x-10,9,x+9,27),c2,c1,2)
   for i in range(4): rect(d,(6+i*10,19+i%2*4,9+i*10,24+i%2*4),c3)
  else:
   for x,y,r in [(14,19,13),(32,17,13),(24,12,14),(18,9,10),(32,8,10)]:ellipse(d,(x-r,y-r,x+r,y+r),c1,c1,1)
   for x,y,r in [(12,14,9),(29,13,10),(22,8,11),(31,22,7),(13,24,6)]:ellipse(d,(x-r,y-r,x+r,y+r),c2,c1,1)
   for x,y in [(10,12),(20,7),(34,14),(13,22),(33,25),(27,6)]:rect(d,(x,y,x+3,y+3),c3)
  if biome=='Boss':
   for i in range(6):
    x=4+i*7; y=18+i%3*5
    d.polygon([(x,y+7),(x+3,y-5),(x+6,y+7)], fill=c3)
 make(f'Biomes/{biome}/Trees/arvore_{variant+1}.png',48,render)
for biome in ['Amazonia','Cerrado','Pantanal','MataAtlantica','Boss']:
 for v in range(3):tree(biome,v)

# Ground props, original little pixel texture.
for biome,tones in {
 'Amazonia':['#355e41','#679557'], 'Cerrado':['#766c3a','#afa05a'],
 'Pantanal':['#3c725f','#72b2a2'], 'MataAtlantica':['#2b6548','#72a46f'],
 'Boss':['#51312e','#bd613f']}.items():
 for v in range(3):
  def render(d,im,tones=tones,v=v):
   for i in range(6):
    x=(i*9+v*7)%44;y=(i*13+v*3)%44
    rect(d,(x,y,x+1+i%2,y+3),tones[i%2])
   if v==1:
    d.polygon([(14,25),(22,13),(28,27)],fill=tones[1]);rect(d,(6,34,9,36),tones[1])
  make(f'Biomes/{biome}/Ground/detalhe_{v+1}.png',48,render)

# Heroes: charming 48x48 figures.
for name,cloth,hat,acc in [('Leo','#6b9db5','#916d49','backpack'),('Helena','#668d54','#48643c','shield'),('Rafael','#3e9595','#49636b','med'),('Clara','#9577ac','#547a5d','book')]:
 def render(d,im):
  d.ellipse((7,41,41,47),fill=(15,30,20,45))
  rect(d,(12,36,22,45),'#352c34');rect(d,(27,36,37,45),'#352c34')
  rect(d,(11,21,38,38),'#24383a');rect(d,(14,21,36,37),cloth)
  rect(d,(8,23,12,35),'#e7b88f');rect(d,(37,23,41,35),'#e7b88f')
  ellipse(d,(14,8,35,28),'#f2c59d','#49382e',2)
  rect(d,(19,17,21,19),'#392f2c');rect(d,(29,17,31,19),'#392f2c')
  rect(d,(14,6,36,12),hat);rect(d,(9,11,40,14),hat)
  if name=='Leo':
   rect(d,(12,27,17,37),'#b98252');rect(d,(16,30,20,32),'#dbb96f')
  elif name=='Helena':
   d.polygon([(23,26),(32,26),(33,34),(28,38),(23,34)],fill='#d5cf78')
  elif name=='Rafael':
   rect(d,(20,27,33,35),'#f4f0df'); rect(d,(25,28,28,34),'#48987a');rect(d,(23,30,31,32),'#48987a')
  elif name=='Clara':
   rect(d,(23,24,37,34),'#d6c68d');rect(d,(25,24,27,34),'#7b624e')
 make(f'Characters/{name}/guardiao.png',48,render)

# Fire wolf boss sprite 72x72, pixel polygon shapes.
def wolf(d,im):
 d.ellipse((6,58,67,70),fill=(16,20,25,70))
 d.polygon([(8,50),(16,35),(16,22),(26,32),(40,17),(42,30),(53,15),(57,30),(66,37),(60,56),(45,61),(23,59)],fill='#dd5729')
 d.polygon([(15,52),(22,28),(29,35),(35,14),(40,33),(46,23),(58,41),(55,58)],fill='#ff9b3f')
 d.polygon([(14,47),(20,31),(34,36),(49,24),(60,41),(52,61),(24,60)],fill='#392d32')
 d.polygon([(23,35),(18,13),(31,24),(39,34),(54,14),(52,43),(40,49)],fill='#593232')
 d.polygon([(20,26),(19,15),(28,29)],fill='#ed833b')
 d.polygon([(48,30),(54,15),(53,37)],fill='#ff9b3f')
 rect(d,(29,38,33,42),'#fff09d');rect(d,(45,37,49,41),'#fff09d')
 rect(d,(36,46,40,49),'#f7743f')
 rect(d,(23,54,29,65),'#423036');rect(d,(50,54,56,65),'#423036')
make('Enemies/FireWolf/lobo_de_fogo.png',72,wolf)

# Icons in pixel language
icons={'health':('#f06f6d','heart'),'water':('#79c9d8','drop'),'power':('#efd079','star'),
'forest':('#8bbf6b','leaf'),'animal':('#e6bd78','paw'),'fire':('#f37a41','flame'),
'garbage':('#bec6aa','bin'),'clock':('#e7d78d','clock'),'seed':('#97cebc','seed')}
for name,(color,kind) in icons.items():
 def render(d,im):
  if kind=='heart':
   d.polygon([(16,29),(4,17),(4,10),(9,6),(15,11),(21,6),(28,10),(28,17)],fill=color)
  elif kind=='drop':d.polygon([(16,3),(25,17),(25,25),(19,29),(12,29),(7,24),(7,18)],fill=color)
  elif kind=='star':d.polygon([(15,3),(19,12),(29,14),(21,21),(23,30),(15,26),(7,30),(9,21),(3,14),(12,12)],fill=color)
  elif kind=='leaf':d.ellipse((5,6,28,26),fill=color);line(d,[(7,28),(22,10)],'#31634d',3)
  elif kind=='paw':
   ellipse(d,(8,15,24,29),color,None,1)
   for x,y in [(5,7),(12,4),(20,5),(26,10)]:ellipse(d,(x,y,x+5,y+6),color,None,1)
  elif kind=='flame':d.polygon([(5,28),(9,14),(13,20),(18,4),(24,17),(28,27),(20,31),(12,30)],fill=color)
  elif kind=='bin':rect(d,(8,10,25,28),color);rect(d,(6,8,27,11),'#8f9b8d')
  elif kind=='clock':ellipse(d,(3,3,28,28),color,'#60543f',2);line(d,[(16,6),(16,16),(23,20)],'#60543f',2)
  elif kind=='seed':d.ellipse((7,8,25,28),fill=color);line(d,[(15,13),(19,8)],'#527d62',2)
 make(f'UI/Icons/{name}.png',32,render)

# Scenic menu 640x360 pixels, nearest-neighbor upscale in-engine.
W,H=640,360
im=Image.new('RGB',(W,H),'#0b292c');d=ImageDraw.Draw(im)
for y in range(H):
 t=y/H
 col=(int(6+9*t),int(28+31*t),int(40+9*t));d.line([(0,y),(W,y)],fill=col)
r=random.Random(9128)
# moon / halo
for rad in range(95,20,-5):
 a=(95-rad)/95
 d.ellipse((480-rad,93-rad,480+rad,93+rad),fill=(int(9+30*a),int(50+38*a),int(56+18*a)))
d.ellipse((450,64,512,126),fill='#cae4b2')
# distant canopy layers
for layer in range(5):
 ybase=166+layer*37
 dark=['#143a39','#1a4a3c','#20553f','#285c40','#315e42'][layer]
 d.rectangle((0,ybase,W,H), fill=dark)
 for x in range(-35,W+50,34):
  cy=ybase-r.randrange(8,52);rr=r.randrange(17,35)
  d.ellipse((x-rr,cy-rr,x+rr,cy+rr),fill=dark)
  if layer>2:
   d.rectangle((x-2,cy,x+3,ybase+5),fill='#34533e')
# silhouetted trunks and tropical palm leaves on borders
for x in [-8,40,87,555,605,652]:
 d.line([(x,H),(x+10,155)],fill='#1b342d',width=10)
 for a in range(10):
  yy=151+r.randrange(-9,10); endx=x+r.randrange(-57,58);endy=yy+r.randrange(-20,40)
  d.line([(x+10,151),(endx,endy)],fill='#15382c',width=6)
# glowy path + water foreground
d.polygon([(220,350),(350,212),(392,213),(505,350)],fill='#5c7755')
d.polygon([(239,350),(352,240),(372,240),(448,350)],fill='#87a16b')
for j in range(44):
 x=r.randrange(W);y=r.randrange(165,355)
 d.rectangle((x,y,x+2,y+3),fill=['#678451','#95a75b','#d0c17b'][j%3])
for j in range(34):
 x=r.randrange(W);y=r.randrange(55,310)
 d.rectangle((x,y,x+1,y+2),fill='#bfe9a7' if j%2 else '#7bd2bb')
root=ROOT/'UI/Panels';root.mkdir(parents=True,exist_ok=True)
im.save(root/'menu_forest.png')

(root/'Art_LICENSE.txt').write_text('Arte 2D autoral gerada para o EcoLabirinto, sem uso de imagens do Pinterest.\nOs sprites Memes são exemplos autorais; substitua pelo seu conteúdo autorizado.\n',encoding='utf8')
(ROOT/'Animals/Memes/README.txt').write_text('Coloque aqui PNGs próprios de animais secretos. Para registrar no jogo, adicione o nome e caminho no Adventure/world.gd e interface.gd. Memes são opcionais e não afetam a missão.\n',encoding='utf8')
print('Gerados',len(list(ROOT.rglob('*.png'))),'PNGs')

# Threat silhouettes - discreet but recognizable.
for name,shirt,hat in [('hunter','#b9574e','#664039'),('logger','#b17c56','#78604b')]:
 def render(d,im):
  d.ellipse((5,38,43,47),fill=(12,20,17,60))
  rect(d,(11,24,21,43),'#424d3c');rect(d,(26,24,38,43),'#3b413f')
  rect(d,(12,18,36,35),shirt)
  rect(d,(6,23,12,33),'#deb58a');rect(d,(37,23,43,33),'#deb58a')
  ellipse(d,(14,7,34,25),'#d0a57c','#453a2d',2)
  rect(d,(11,7,37,13),hat);rect(d,(16,3,32,10),hat)
  rect(d,(19,17,21,19),'#31312c');rect(d,(28,17,30,19),'#31312c')
  if name=='hunter':
   rect(d,(40,17,43,37),'#606d5d');rect(d,(41,13,44,18),'#abb1a0')
  else:
   d.polygon([(39,16),(45,21),(43,37),(39,34)],fill='#d7c7ae')
 make('Enemies/'+name+'/sprite.png',48,render)

# Revisão de silhuetas: estas espécies são reconhecíveis mesmo em 40 px.
def capy(d,im):
 d.ellipse((5,40,44,46),fill=(0,0,0,48))
 ellipse(d,(12,13,45,38),'#ba8c60','#483a2f',2)
 ellipse(d,(3,19,23,33),'#b78960','#483a2f',2)
 ellipse(d,(3,22,13,32),'#946542','#483a2f',1)
 ellipse(d,(14,14,20,21),'#a77753','#483a2f',1)
 rect(d,(15,22,17,24),'#292923')
 rect(d,(8,28,11,30),'#493b30')
 for x in [17,34]:rect(d,(x,33,x+5,42),'#9c704d');rect(d,(x,40,x+7,43),'#4e3e30')
 d.polygon([(36,16),(44,24),(41,37),(29,35)],fill='#bf9063')
make('Animals/Mission/capivara.png',48,capy)
def caiman(d,im):
 d.ellipse((3,38,44,45),fill=(0,0,0,45))
 d.polygon([(31,29),(46,35),(44,39),(26,36)],fill='#527344')
 ellipse(d,(9,22,36,37),'#598b57','#2b3c2f',2)
 d.polygon([(15,21),(4,23),(3,32),(17,34),(27,29)],fill='#648b57')
 d.polygon([(5,31),(13,35),(25,33)],fill='#bec89a')
 ellipse(d,(12,17,19,24),'#6aa465','#314333',2)
 ellipse(d,(27,16,34,24),'#6aa465','#314333',2)
 rect(d,(16,20,18,22),'#1c2b27');rect(d,(30,19,32,21),'#1c2b27')
 for x in [17,28]:rect(d,(x,35,x+4,40),'#39533b')
make('Animals/Mission/jacare.png',48,caiman)
def armadillo(d,im):
 d.ellipse((5,40,42,45),fill=(0,0,0,45))
 ellipse(d,(10,14,39,35),'#a18c63','#42382c',2)
 for x in range(15,37,5):d.arc((x-8,13,x+4,35),-80,80,fill='#584534',width=2)
 d.polygon([(14,27),(3,25),(4,31),(16,35)],fill='#b5a47e')
 d.polygon([(34,24),(46,31),(42,34),(35,32)],fill='#7d674f')
 rect(d,(6,27,8,29),'#2b2926')
 for x in [15,29]:rect(d,(x,34,x+4,41),'#806b52')
make('Animals/Mission/tatu.png',48,armadillo)
def anteater(d,im):
 d.ellipse((5,39,44,45),fill=(0,0,0,47))
 d.polygon([(15,18),(33,18),(42,23),(41,36),(16,37),(12,30)],fill='#888b82')
 d.polygon([(16,17),(10,24),(2,32),(4,35),(18,28)],fill='#e7cbaa')
 d.polygon([(16,24),(30,23),(34,29),(23,33)],fill='#f6e6c8')
 d.polygon([(28,16),(43,18),(47,32),(39,34)],fill='#3f3c38')
 rect(d,(12,22,14,24),'#282b28')
 for x in [17,34]:rect(d,(x,34,x+4,42),'#5e605a')
make('Animals/Mission/tamandua.png',48,anteater)
