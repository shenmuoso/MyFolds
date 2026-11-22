"""Build editable native glass icons and previews using Apple's local renderer."""
from pathlib import Path
import json, shutil, subprocess
root=Path(__file__).resolve().parent
renderer='/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool'

def group(asset,name,translucency,blur,strength,depth,shadow=.24):
 return {'name':name,'layers':[{'image-name':asset,'name':name}], 'blur-material':blur,'refractivity':{'enabled':True,'strength':strength,'depth':depth},'specular':'inside','shadow':{'kind':'neutral','opacity':shadow},'translucency':{'enabled':True,'value':translucency}}

variants={
 'MyFolds-Fold':[
  group('03-fold-return.svg','01 · Rear fold',.80,.08,.80,.26),
  group('01-fold-left.svg','02 · Cyan leaf',.86,.12,.85,.32),
  group('02-fold-right.svg','03 · Frosted leaf',.92,.12,.85,.32)
 ],
 'MyFolds-Folder':[
  group('04-folder-back.svg','01 · Folder back',.80,.12,.85,.32),
  group('05-folder-sheet.svg','02 · File leaf',.80,.12,.85,.32),
  group('06-folder-front.svg','03 · Frosted cover',.92,.12,.85,.32),
  group('07-folder-fold.svg','04 · Folded lip',.80,.12,.85,.32)
 ]
}
(root/'previews').mkdir(exist_ok=True)
for name,groups in variants.items():
 folder=root/(name+'.icon'); (folder/'Assets').mkdir(parents=True,exist_ok=True)
 for g in groups:
  asset=g['layers'][0]['image-name']; shutil.copyfile(root/'layers'/asset,folder/'Assets'/asset)
 doc={'features':['refractivity','specular-location'],'fill':{'automatic-gradient':'extended-srgb:0.89,0.905,0.93,1.0'},'groups':list(reversed(groups)),'supported-platforms':{'squares':'shared'}}
 (folder/'icon.json').write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n')
 for rendition in ['Default','Dark']:
  for size in [32,64,128,1024]:
   suffix='' if size==1024 else f'-{size}'
   subprocess.run([renderer,str(folder),'--export-image','--output-file',str(root/'previews'/f'{name}-{rendition}{suffix}.png'),'--platform','macOS','--rendition',rendition,'--width',str(size),'--height',str(size),'--scale','1','--design-generation','27'],check=True,stdout=subprocess.DEVNULL)
print('Rendered 2 layered designs in default and dark appearance at 32, 64, 128 and 1024 px.')
