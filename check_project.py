"""Offline static QA for the Godot project. This is NOT a Godot runtime test."""
from pathlib import Path
import re, os
ROOT=Path(__file__).parent
errors=[]
for p in (ROOT/'Adventure').glob('*.gd'):
 s=p.read_text()
 stack=[]; state='code'; q=''; escape=False; line=1
 for c in s:
  if c=='\n':
   line+=1
   if state=='comment':state='code'
   continue
  if state=='comment':continue
  if state=='string':
   if escape:escape=False
   elif c=='\\':escape=True
   elif c==q:state='code'
   continue
  if c=='#':state='comment';continue
  if c in "'\"":q=c;state='string';continue
  if c in '([{':stack.append((c,line))
  if c in ')]}':
   if not stack: errors.append(f'{p.name}:{line}: unmatched {c}');continue
   before,at=stack.pop()
   if ('(',')')==(before,c) or ('[',']')==(before,c) or ('{','}')==(before,c):continue
   errors.append(f'{p.name}:{line}: mismatched {before}@{at} {c}')
 if stack:errors.append(f'{p.name}: unclosed {stack[-1]}')
 if state=='string':errors.append(f'{p.name}: unclosed string')
 funcs=re.findall(r'^func\s+(\w+)\s*\(',s,re.M)
 if len(funcs)!=len(set(funcs)):errors.append(f'{p.name}: duplicate funcs')
 for n,l in enumerate(s.splitlines(),1):
  pref=l[:len(l)-len(l.lstrip())]
  if ' ' in pref and '\t' in pref: errors.append(f'{p.name}:{n}: mixed spaces tabs')
  elif len(pref)>0 and ' ' in pref and len(pref.strip())==0:
   if l.strip():errors.append(f'{p.name}:{n}: leading spaces in tab project')
 for resource in re.findall(r'preload\("(res://[^\"]+)"\)',s):
  if not (ROOT/resource.removeprefix('res://')).is_file():errors.append(f'{p.name}: missing {resource}')
for resource in re.findall(r'res://Assets/[^"\n]*?\.png', (ROOT/'Adventure'/'interface.gd').read_text()):
 if '%' not in resource and not (ROOT/resource.removeprefix('res://')).is_file():errors.append(f'asset missing {resource}')
assert (ROOT/'project.godot').is_file()
assets=list((ROOT/'Assets').rglob('*.png'))
assert len(assets)>60, f'few assets: {len(assets)}'
from PIL import Image
for p in assets:
 try:
  with Image.open(p) as im:
   im.verify()
 except Exception as e: errors.append(f'{p}: PNG invalid {e}')
print(f'{len(assets)} PNGs; {len(list((ROOT / "Adventure").glob("*.gd")))} scripts; {len(errors)} erros estáticos')
if errors:
 print('\n'.join(errors[:70]));raise SystemExit(1)

# Guardrails V7: required modules, no scrolling in the gameplay HUD, and no full-map redraw on threats.
for module in ["theme_palette", "terrain_layer", "ambient_fx", "qa_v7", "qa_seeds_v7"]:
 if not (ROOT/'Adventure'/f'{module}.gd').is_file():errors.append(f'missing V7 module: {module}')
world=(ROOT/'Adventure'/'world.gd').read_text()
main=(ROOT/'Adventure'/'main.gd').read_text()
ui=(ROOT/'Adventure'/'interface.gd').read_text()
if 'terrain_layer.call("rebuild", self)' not in world:errors.append('terrain cache not used')
if 'func _physics_process(delta: float)' not in main:errors.append('fixed-time movement missing')
if 'var movement: Vector2 = Vector2.ZERO' not in main:errors.append('movement code missing')
if 'ScrollContainer.new()' in ui[ui.index('func _build_hud()'):ui.index('func show_details')]:errors.append('game HUD contains scroll')
for name in ['rescue','collect','water','heal','damage','boss']:
 if not (ROOT/'Assets'/'Audio'/(name+'.wav')).is_file():errors.append('missing audio '+name)
if errors:
 print('V7 contract check failed:');print('\n'.join(errors));raise SystemExit(1)
print('V7 contract: terrain cache, 60 Hz movement hook, UI and audio references OK')
