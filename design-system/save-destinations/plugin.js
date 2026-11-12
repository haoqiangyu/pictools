const TARGET_PAGE='13:606';
const TITLE='Pictools Studio / UI·UX 2.0';
const D={}; const C={}; const V={}; const VD={}; const ST={}; const styleAssignments=[]; const screens={}; const routes=[]; const ledger={createdNodeIds:[],variables:{},components:{},screens:{},warnings:[]};
let page,root,library,photoHash,stillHash,lightMode,darkMode,colorCollection;
const palette={bg:['F7F6F2','171B18'],surface:['FFFFFF','232925'],subtle:['EEEDE7','303831'],ink:['202522','F5F5EF'],muted:['626B65','B1BAB2'],border:['DADDD5','465047'],primary:['C84725','FFAE8F'],primaryInk:['FFFFFF','432313'],tint:['FAE8DF','4B3027'],canvas:['202522','101411'],canvasInk:['FAFAF4','FAFAF4'],canvasMuted:['B9C4BA','B9C4BA'],success:['23744B','8CD6AF'],successTint:['E5F2E9','1F3B2C'],warning:['8A5A1B','EAC589'],warningTint:['F8EFD8','413724'],danger:['B63232','FFAEAA'],dangerTint:['FCE9E6','482C2A'],focus:['295BA8','94BCFF'],disabled:['E4E6DF','343D35'],disabledInk:['70796F','AFB8AF']};
function rgb(hex){return {r:parseInt(hex.slice(0,2),16)/255,g:parseInt(hex.slice(2,4),16)/255,b:parseInt(hex.slice(4,6),16)/255};}
function rgba(hex){return {...rgb(hex),a:1};}
function paint(key){let p={type:'SOLID',color:rgb(palette[key]?palette[key][0]:key)};return V[key]?figma.variables.setBoundVariableForPaint(p,'color',V[key]):p;}
function color(n,key){n.fills=key?[paint(key)]:[];return n;}
function bind(n,prop,value){if(V['space/'+value])n.setBoundVariable(prop,V['space/'+value]);else n[prop]=value;}
function tracked(n,name){n.name=name;ledger.createdNodeIds.push(n.id);return n;}
function frame(parent,name,w,h,bg){const n=tracked(figma.createFrame(),name);n.resize(w,h);color(n,bg);n.clipsContent=false;if(parent)parent.appendChild(n);return n;}
function auto(parent,name,w,dir='VERTICAL',gap=12,pad=0,bg){const n=frame(parent,name,w,1,bg);n.layoutMode=dir;n.primaryAxisSizingMode=dir==='VERTICAL'?'AUTO':'FIXED';n.counterAxisSizingMode=dir==='VERTICAL'?'FIXED':'AUTO';bind(n,'itemSpacing',gap);for(const k of ['paddingTop','paddingRight','paddingBottom','paddingLeft'])bind(n,k,pad);return n;}
function fill(n){n.layoutSizingHorizontal='FILL';return n;}
function fixed(n,w,h){n.resize(w,h);n.primaryAxisSizingMode='FIXED';n.counterAxisSizingMode='FIXED';return n;}
function radius(n,v){if(V['radius/'+v])n.setBoundVariable('cornerRadius',V['radius/'+v]);else n.cornerRadius=v;return n;}
function line(parent,w,key='border'){const n=frame(parent,'Divider',w,1,key);return n;}
function rect(parent,name,x,y,w,h,key,r=0){const n=tracked(figma.createRectangle(),name);parent.appendChild(n);n.resize(w,h);n.x=x;n.y=y;color(n,key);radius(n,r);return n;}
function text(parent,str,size=14,key='ink',weight='Regular',width){const n=tracked(figma.createText(),str.replace(/\n/g,' / ').slice(0,60));parent.appendChild(n);const family=/[\u3000-\u9fff]/.test(str)?'Noto Sans SC':'Roboto';n.fontName={family,style:weight};n.characters=str;n.fontSize=size;n.lineHeight={unit:'PIXELS',value:Math.ceil(size*1.45)};n.letterSpacing={unit:'PIXELS',value:0};color(n,key);if(ST[family+'/'+size+'/'+weight])styleAssignments.push([n,ST[family+'/'+size+'/'+weight]]);if(width){n.resize(width,10);n.textAutoResize='HEIGHT';}else n.textAutoResize='WIDTH_AND_HEIGHT';return n;}
function body(parent,str,size=14,key='muted',weight='Regular'){return text(parent,str,size,key,weight,parent.width-parent.paddingLeft-parent.paddingRight);}
function spacer(parent,h){return frame(parent,'Space',1,h);}
function place(n,x,y){n.x=x;n.y=y;return n;}
function outline(n,key='border',weight=1){n.strokes=[paint(key)];n.strokeWeight=weight;return n;}
function svg(parent,name,data,size=24){const n=tracked(figma.createNodeFromSvg(data),name);parent.appendChild(n);const factor=size/n.width;n.rescale(factor);n.fills=[];return n;}
function markSVG(bg='C84725',fg='FFFFFF',rounded=true){return '<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">'+(bg?'<rect width="128" height="128" rx="'+(rounded?28:0)+'" fill="#'+bg+'"/>':'')+'<path d="M31 57V36a5 5 0 0 1 5-5h21M71 97h21a5 5 0 0 0 5-5V71" fill="none" stroke="#'+fg+'" stroke-width="10" stroke-linecap="round"/><path d="M38 87V73l16-16 18 18 15-15v27H38Z" fill="#'+fg+'"/><circle cx="84" cy="44" r="8" fill="#'+fg+'"/></svg>';}
function icon(parent,name,key='ink',size=24){const c=C['icon/'+name];if(c){const i=c.createInstance();parent.appendChild(i);i.rescale(size/24);i.name='Icon / '+name;for(const v of i.findAll(n=>n.type==='VECTOR'))color(v,key);return i;}throw new Error('Missing icon '+name);}
function iButton(parent,name,key='ink',bg){const n=auto(parent,'Icon button / '+name,48,'HORIZONTAL',0,0,bg);fixed(n,48,48);n.primaryAxisAlignItems='CENTER';n.counterAxisAlignItems='CENTER';radius(n,12);icon(n,name,key);return n;}
function link(node,to){routes.push({node,to});return node;}
function button(parent,label,width,variant='Primary',state='Default',to){const c=C['button/'+variant+'/'+state]||C['button/'+variant+'/Default'];const i=c.createInstance();parent.appendChild(i);i.resize(width,48);i.name='Button / '+label;const t=i.findOne(n=>n.type==='TEXT');t.characters=label;if(to)link(i,to);return i;}
function pill(parent,label,selected=false,w){const i=C['chip/'+(selected?'Selected':'Default')].createInstance();parent.appendChild(i);i.name='Chip / '+label;const t=i.findOne(n=>n.type==='TEXT');t.characters=label;if(w)i.resize(w,44);return i;}
function tag(parent,label,kind='subtle'){const a=auto(parent,'Status / '+label,70,'HORIZONTAL',4,0,kind);a.counterAxisSizingMode='AUTO';a.counterAxisAlignItems='CENTER';a.paddingLeft=8;a.paddingRight=8;a.paddingTop=4;a.paddingBottom=4;radius(a,4);text(a,label,12,kind==='successTint'?'success':kind==='warningTint'?'warning':kind==='dangerTint'?'danger':'muted','Medium');return a;}
function field(parent,label,value,w,state='Default'){const a=auto(parent,'Field / '+label,w,'VERTICAL',6);text(a,label,13,'muted','Medium');const c=C['field/'+state].createInstance();a.appendChild(c);c.resize(w,52);c.findOne(n=>n.type==='TEXT').characters=value;return a;}
function photo(parent,w,h,kind='coast',dim=false){const n=frame(parent,'Content image / '+kind,w,h);n.fills=[{type:'IMAGE',imageHash:kind==='still'?stillHash:photoHash,scaleMode:'FILL'}];n.clipsContent=true;if(dim){const shade=rect(n,'原图曝光示意',0,0,w,h,'000000');shade.opacity=.28;}return n;}
function caption(parent,left,right){const r=auto(parent,'Meta',parent.width-parent.paddingLeft-parent.paddingRight,'HORIZONTAL',8);r.counterAxisAlignItems='CENTER';const t=text(r,left,12,'muted');t.layoutGrow=1;if(right)text(r,right,12,'muted');return r;}
function alert(parent,title,desc,kind='warning',w){const a=auto(parent,'Notice / '+title,w||parent.width,'HORIZONTAL',10,12,kind+'Tint');radius(a,8);icon(a,kind==='success'?'check_circle':kind==='danger'?'error':'info_outline_rounded',kind,20);const c=auto(a,'Message',a.width-54,'VERTICAL',4);text(c,title,14,kind,'Medium',c.width);if(desc)text(c,desc,13,kind,'Regular',c.width);return a;}
function row(parent,label,value,ico,to){const r=auto(parent,'Row / '+label,parent.width-parent.paddingLeft-parent.paddingRight,'HORIZONTAL',12,0);fixed(r,parent.width-parent.paddingLeft-parent.paddingRight,64);r.counterAxisAlignItems='CENTER';if(ico)icon(r,ico,'muted');const t=text(r,label,16);t.layoutGrow=1;if(value)text(r,value,14,'muted');icon(r,'chevron_right_rounded','muted',20);if(to)link(r,to);return r;}
function status(parent,w=390,dark=false){const r=auto(parent,'Safe area / status',w,'HORIZONTAL',8,0);fixed(r,w,44);r.paddingLeft=24;r.paddingRight=24;r.primaryAxisAlignItems='SPACE_BETWEEN';r.counterAxisAlignItems='CENTER';text(r,'9:41',14,dark?'canvasInk':'ink','Medium');const a=auto(r,'System status',64,'HORIZONTAL',6);a.counterAxisSizingMode='AUTO';icon(a,'signal_cellular_4_bar',dark?'canvasInk':'ink',14);icon(a,'wifi',dark?'canvasInk':'ink',14);icon(a,'battery_full',dark?'canvasInk':'ink',14);return r;}
function homeIndicator(parent,w,dark=false){const a=auto(parent,'Safe area / home indicator',w,'HORIZONTAL',0);fixed(a,w,24);a.primaryAxisAlignItems='CENTER';a.counterAxisAlignItems='CENTER';const b=frame(a,'Home indicator',128,4,dark?'canvasInk':'ink');radius(b,999);return a;}
function header(parent,title,opt={}){const w=parent.width;const r=auto(parent,'Navigation / '+title,w,'HORIZONTAL',4,0,opt.bg);fixed(r,w,60);r.paddingLeft=12;r.paddingRight=12;r.counterAxisAlignItems='CENTER';if(opt.brand){svg(r,'Pictools symbol',markSVG(),30);spacer(r,1);const t=text(r,'Pictools',22,'ink','Bold');t.layoutGrow=1;link(iButton(r,'settings_outlined'),'settings');}else{link(iButton(r,'chevron_left',opt.dark?'canvasInk':'ink'),opt.back||'home');const t=text(r,title,18,opt.dark?'canvasInk':'ink','Bold');t.layoutGrow=1;if(opt.action){button(r,opt.action,72,'Quiet','Default',opt.to);}else if(opt.reset)link(iButton(r,'refresh',opt.dark?'canvasInk':'ink'),'reset');else link(iButton(r,'more_horiz',opt.dark?'canvasInk':'ink'),'image-menu');}return r;}
function phone(id,name,w=390,h=844,opt={}){const s=auto(null,name,w,'VERTICAL',0,0,opt.dark?'canvas':'bg');fixed(s,w,h);s.clipsContent=true;radius(s,24);if(opt.mode==='Dark')s.setExplicitVariableModeForCollection(colorCollection,darkMode);else s.setExplicitVariableModeForCollection(colorCollection,lightMode);status(s,w,opt.dark);if(!opt.noHeader)header(s,opt.title||name,opt);const content=auto(s,'Scrollable content',w,'VERTICAL',16,20);content.layoutSizingVertical='FILL';content.clipsContent=true;content.overflowDirection='VERTICAL';screens[id]=s;ledger.screens[id]=s.id;D[id]={s,content};return D[id];}
function footer(d,label,to,variant='Primary',extra){const w=d.s.width;const f=auto(d.s,'Persistent action / safe bottom',w,'VERTICAL',8,0,'surface');f.paddingLeft=20;f.paddingRight=20;f.paddingTop=12;if(extra)text(f,extra,12,'muted','Regular',w-40);button(f,label,w-40,variant,'Default',to);homeIndicator(f,w-40);return f;}
function segment(parent,labels,selected,targets){const r=auto(parent,'Segmented control',parent.width-parent.paddingLeft-parent.paddingRight,'HORIZONTAL',4,4,'subtle');radius(r,12);const w=(r.width-8-4*(labels.length-1))/labels.length;labels.forEach((label,i)=>{const p=pill(r,label,i===selected,w);if(targets&&targets[i])link(p,targets[i]);});return r;}
function slider(parent,label,value,frac=.5,dark=false){const a=auto(parent,'Slider / '+label,parent.width-parent.paddingLeft-parent.paddingRight,'VERTICAL',6);const r=auto(a,'Label and value',a.width,'HORIZONTAL',8);text(r,label,14,dark?'canvasInk':'ink').layoutGrow=1;text(r,value,14,dark?'canvasInk':'ink','Medium');const bar=frame(a,'Slider hit target / 48',a.width,48);rect(bar,'Track',0,22,a.width,4,dark?'border':'subtle',2);rect(bar,'Progress',0,22,a.width*frac,4,'primary',2);const thumb=tracked(figma.createEllipse(),'Slider thumb');bar.appendChild(thumb);thumb.resize(24,24);thumb.x=Math.max(0,a.width*frac-12);thumb.y=12;color(thumb,'primary');return a;}
function fileRow(parent,name,detail,state='Ready',kind='coast',to){const a=auto(parent,'File / '+name,parent.width-parent.paddingLeft-parent.paddingRight,'HORIZONTAL',12,12,'surface');radius(a,8);photo(a,52,52,kind);const c=auto(a,'File metadata',a.width-148,'VERTICAL',4);text(c,name,14,'ink','Medium',c.width);text(c,detail,12,state==='Error'?'danger':state==='Saved'?'success':'muted','Regular',c.width);const ic=state==='Saved'?'check_circle':state==='Error'?'refresh':'more_horiz';const b=iButton(a,ic,state==='Saved'?'success':state==='Error'?'danger':'muted');b.resize(48,48);if(to)link(b,to);return a;}
function toolGrid(parent,targets=['compare-empty','crop-empty','enhance-empty','convert-empty'],single=false){const entries=[['compare','图片对比','滑块 · 并排 · 叠加'],['crop','裁剪与尺寸','构图与像素一起调整'],['wb_sunny','亮度增强','一键改善明暗'],['transform','格式转换','多张图片一起处理']];for(let n=0;n<entries.length;n+=(single?1:2)){const r=auto(parent,'Tool row',parent.width,'HORIZONTAL',12);for(let j=0;j<(single?1:2);j++){const k=n+j,[ic,title,desc]=entries[k];const c=C['tool/'+ic].createInstance();r.appendChild(c);c.resize(single?r.width:(r.width-12)/2,126);link(c,targets[k]);}}}
function section(parent,kicker,title,desc){const a=auto(parent,kicker+' / '+title,parent.width-parent.paddingLeft-parent.paddingRight,'VERTICAL',24);const head=auto(a,'Section heading',a.width,'VERTICAL',8);text(head,kicker,13,'primary','Bold');text(head,title,28,'ink','Bold');if(desc)text(head,desc,15,'muted','Regular',a.width);return a;}
function screenRow(parent,items){const r=auto(parent,'Screens',parent.width,'HORIZONTAL',32);r.counterAxisAlignItems='MIN';for(const [id,title,note] of items){const d=D[id];const c=auto(r,'Specimen / '+title,d.s.width,'VERTICAL',12);text(c,title,14,'ink','Bold',c.width);c.appendChild(d.s);if(note)text(c,note,13,'muted','Regular',c.width);}return r;}

async function init(){
  root=await figma.getNodeByIdAsync('18:781');library=await figma.getNodeByIdAsync('18:782');
  for(const family of ['Noto Sans SC','Roboto'])for(const style of ['Regular','Medium','Bold'])await figma.loadFontAsync({family,style});
  const collections=await figma.variables.getLocalVariableCollectionsAsync();colorCollection=collections.find(c=>c.name==='Studio 2.0 / Semantic');lightMode=colorCollection.modes.find(m=>m.name==='Light').modeId;darkMode=(colorCollection.modes.find(m=>m.name==='Dark')||colorCollection.modes[0]).modeId;
  for(const coll of collections.filter(c=>['Studio 2.0 / Semantic','Studio 2.0 / Primitives','Studio 2.0 / Dark'].includes(c.name))){for(const id of coll.variableIds){const v=await figma.variables.getVariableByIdAsync(id);if(coll.name==='Studio 2.0 / Semantic')V[v.name.replace('color/','')]=v;else if(coll.name==='Studio 2.0 / Dark')VD[v.name.replace('color/','')]=v;else if(v.resolvedType==='FLOAT')V[v.name]=v;}}
  for(const [key,v]of Object.entries(V))ledger.variables[key]=v.id;
  for(const st of await figma.getLocalTextStylesAsync())if(st.name.startsWith('Studio 2.0/'))ST[st.name.replace('Studio 2.0/','')]=st.id;
  for(const n of library.findAll(n=>n.type==='COMPONENT')){let key;if(n.name.startsWith('Studio/Icon/'))key='icon/'+n.name.replace('Studio/Icon/','');else if(n.name.startsWith('Variant=')){const m=n.name.match(/Variant=(\w+), State=(\w+)/);key='button/'+m[1]+'/'+m[2];}else if(n.name.startsWith('Studio/Chip/'))key='chip/'+n.name.split('/')[2];else if(n.name.startsWith('Studio/Field/'))key='field/'+n.name.split('/')[2];else if(n.name.startsWith('Studio/Tool/'))key='tool/'+n.name.split('/')[2];else if(n.name.startsWith('Studio/Switch/'))key='switch/'+n.name.split('/')[2];else if(n.name==='Studio/Brand/App icon')key='logo';if(key){C[key]=n;ledger.components[key]=n.id;}}

}
let stage='init';
async function nav(node,target){stage='nav '+node.id+' -> '+target.id+' '+target.name;await node.setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:target.id,navigation:'NAVIGATE',transition:{type:'DISSOLVE',easing:{type:'EASE_OUT'},duration:.18},resetScrollPosition:true}]}]);}
function changeText(tree,from,to){for(const t of tree.findAll(n=>n.type==='TEXT'&&n.characters.includes(from)))t.characters=t.characters.split(from).join(to);}
function renameButton(n,label){n.name='Button / '+label;n.findOne(x=>x.type==='TEXT').characters=label;}
function screenOf(n){let p=n.parent;while(p&&p.parent&&p.parent.type!=='SECTION'&&p.parent.type!=='PAGE'&&!p.parent.name.startsWith('Specimen')){if(p.name.startsWith('Prototype /')||p.name.startsWith('Duo /'))return p;p=p.parent;}return p;}
function notes(parent,str){return text(parent,str,12,'muted','Regular',parent.width-parent.paddingLeft-parent.paddingRight);}
(async()=>{
 page=await figma.getNodeByIdAsync(TARGET_PAGE);await figma.setCurrentPageAsync(page);await init();
 photoHash=page.findOne(n=>n.name==='Content image / coast' && n.fills?.[0]?.imageHash)?.fills[0].imageHash;stillHash=page.findOne(n=>n.name==='Content image / still' && n.fills?.[0]?.imageHash)?.fills[0].imageHash;
 const previous=page.findOne(n=>n.name==='09 / Save destinations · Photos + Files');if(previous && previous.getPluginData('saveDestinationsReport'))throw new Error('Completed design exists; do not rerun.');
 if(previous)previous.remove();for(const n of [...page.children])if(n.name.startsWith('Save 2.1 /')||n.name==='10 / Photos prototype results')n.remove();
 const report={updated:[],created:{},warnings:[]};
 // Preserve existing file-save prototype routes, and add the second destination.
 const original=page.findAll(n=>n.type==='INSTANCE'&&(n.name==='Button / 保存副本'||n.name==='Button / 保存到文件'));
 for(const file of original){
   const container=file.parent;const frame=screenOf(file);const name=frame.name;
   const eligible=/(-png|-jpg|export-jpg)/.test(name)||frame.id==='18:2760';
   const photo=container.children.find(n=>n.name==='Button / 保存到相册')||button(container,'保存到相册',file.width,'Primary',eligible?'Default':'Disabled');
   container.insertChild(container.children.indexOf(file),photo);
   stage='existing file '+file.id;const reactions=file.reactions;
   file.swapComponent(C['button/Secondary/Default']);renameButton(file,'保存到文件');/* Component swaps preserve instance prototype reactions. */
   if(!eligible && !container.children.some(n=>n.type==='TEXT'&&n.characters.startsWith('相册支持'))){const hint=notes(container,'相册支持 PNG/JPEG；其他格式请保存到文件。');container.insertChild(container.children.indexOf(file),hint);}
   if(container.name==='Export sheet / fold-aware'){
     if(container.height>container.parent.height-40){container.resize(container.width,container.parent.height-40);container.primaryAxisSizingMode='FIXED';container.clipsContent=true;container.overflowDirection='VERTICAL';}
     container.y=Math.max(20,(container.parent.height-container.height)/2);
   }
   report.updated.push({frame:frame.id,file:file.id,photo:photo.id,eligible});
 }
 // Existing success nodes represent completed file-picker flows.
 for(const t of page.findAll(n=>n.type==='TEXT'&&n.characters==='图片已保存'))t.characters='已保存到文件';
 for(const t of page.findAll(n=>n.type==='TEXT'&&n.characters.includes('已保存 ·')))t.characters=t.characters.replace('已保存 ·','已存文件 ·');
 for(const t of page.findAll(n=>n.type==='TEXT'&&n.characters.includes('完成编码 ≠ 已保存。')))t.characters='编码完成后选择相册或文件。只有系统写入成功才标记对应去向；取消、失败时保留结果。';
 for(const t of page.findAll(n=>n.type==='TEXT'&&n.characters.includes('逐文件状态：')))t.characters='分别记录相册与文件的保存状态；已成功的去向不重复写入。批量相册仅保存 PNG/JPEG，其他结果保留。';
 const board=auto(page,'09 / Save destinations · Photos + Files',2940,'VERTICAL',48,40,'bg');board.x=10600;board.y=0;
 text(board,'保存到你需要的地方',36,'ink','Bold');
 text(board,'Pictools Studio · Export 2.1',14,'primary','Bold');
 notes(board,'相册：PNG/JPEG 新副本 · 文件：全部 6 种格式 · 分别记录保存状态 · 取消或拒绝权限后保留结果');
 const made={};
 async function clone(key,id,label){const src=await figma.getNodeByIdAsync(id);const s=(src.children?.find(n=>n.name.startsWith('Product viewport /'))||src).clone();s.name='Save 2.1 / '+key;made[key]=s;report.created[key]=s.id;return s;}
 const phonePng=await clone('phone-png','19:8397','');
 const unsupported=await clone('phone-webp','19:6193','');
 const permission=await clone('phone-permission','19:8397','');
 const savedPhotos=await clone('phone-saved-photos','19:8469','');changeText(savedPhotos,'已保存到文件','已保存到相册');
 const savedFiles=await clone('phone-saved-files','19:8469','');
 const savedBoth=await clone('phone-saved-both','19:8469','');changeText(savedBoth,'已保存到文件','已保存到相册和文件');
 const batch=await clone('batch-destination','19:8397','');
 const outer=await clone('duo-outer-png','21:15856','');
 const inner=await clone('duo-inner-png','21:15636','');
 const book=await clone('duo-book-png','21:15746','');
 const dark=phonePng.clone();dark.name='Save 2.1 / phone-dark';dark.setExplicitVariableModeForCollection(colorCollection,darkMode);made['phone-dark']=dark;report.created['phone-dark']=dark.id;
 for(const s of [outer,inner,book]){
   const sh=s.findOne(n=>n.name==='Export sheet / fold-aware');
   for(const t of sh.findAll(n=>n.type==='TEXT'&&n.characters==='WebP'))t.characters='PNG';
   changeText(sh,'.webp','.png');
   for(const n of sh.findAll(n=>n.name==='Slider / 图像质量'))n.visible=false;
   for(const t of sh.findAll(n=>n.type==='TEXT'&&n.characters.startsWith('相册支持')))t.visible=false;
   const photo=sh.findOne(n=>n.name==='Button / 保存到相册');photo.swapComponent(C['button/Primary/Default']);renameButton(photo,'保存到相册');
   sh.primaryAxisSizingMode='AUTO';sh.y=Math.max(20,(s.height-sh.height)/2);
 }
 const permissionContent=permission.findOne(n=>n.name==='Scrollable content');
 const notice=alert(permissionContent,'尚未获得相册添加权限','结果仍保留。可打开系统设置授权，或保存到文件。','warning',permissionContent.width-40);
 permissionContent.insertChild(0,notice);
 const settings=button(permissionContent,'打开系统设置',permissionContent.width-40,'Quiet');permissionContent.insertChild(1,settings);await nav(settings,phonePng);
 for(const [s,target,label]of [[savedPhotos,savedBoth,'保存到文件'],[savedFiles,savedBoth,'保存到相册']]){
   const f=s.findOne(n=>n.name==='Persistent action / safe bottom')||s.findOne(n=>n.name==='Scrollable content');const b=button(f,label,f.width-40,'Secondary');f.insertChild(0,b);await nav(b,target);
 }
 // Full-screen phone and foldable export destinations retain the existing editor context.
 for(const s of [phonePng,permission,dark,outer,inner,book]){
   await nav(s.findOne(n=>n.name==='Button / 保存到相册'),savedPhotos);
   await nav(s.findOne(n=>n.name==='Button / 保存到文件'),savedFiles);
 }
 await nav(unsupported.findOne(n=>n.name==='Button / 保存到文件'),savedFiles);
 const c=batch.findOne(n=>n.name==='Scrollable content');for(const n of [...c.children])n.remove();
 text(c,'选择保存位置',24,'ink','Bold');notes(c,'3 张结果已准备好');
 alert(c,'相册支持 PNG/JPEG','本批次仅保存 2 张兼容图片。WebP 结果保留，可保存到文件。','warning',350);
 fileRow(c,'海岸漫步.png','PNG · 等待保存');fileRow(c,'静物习作.jpg','JPEG · 等待保存','Ready','still');fileRow(c,'背景素材.webp','WebP · 请保存到文件');
 const bf=batch.findOne(n=>n.name==='Persistent action / safe bottom');for(const n of [...bf.children])n.remove();
 await nav(button(bf,'保存到相册 · 2 张',350),savedPhotos);await nav(button(bf,'保存到文件 · 3 张',350,'Secondary'),savedFiles);homeIndicator(bf,350);
 // Keep new fixtures editable and reuse the existing library components/tokens.
 function rowScreens(title,entries){const sec=auto(board,title,2860,'VERTICAL',20);text(sec,title,24,'ink','Bold');const row=auto(sec,'Screens',2860,'HORIZONTAL',32);row.counterAxisAlignItems='MIN';for(const [s,label]of entries){const spec=auto(row,'Specimen / '+label,s.width,'VERTICAL',12);text(spec,label,14,'ink','Bold',s.width);spec.appendChild(s);}}
 rowScreens('01 / 选择去向与兼容性',[[phonePng,'PNG · 两种保存去向'],[unsupported,'WebP · 保存到文件'],[permission,'拒绝权限 · 结果保留'],[batch,'批量 · 明确兼容数量'],[dark,'深色模式']]);
 rowScreens('02 / 分别记录完成状态',[[savedPhotos,'已保存到相册'],[savedFiles,'已保存到文件'],[savedBoth,'两个去向均已保存']]);
 rowScreens('03 / iPhone Duo · 各姿态沿用同一导出状态',[[outer,'外屏 · 两种去向'],[inner,'展开内屏 · 导出弹窗'],[book,'书本姿态 · 避开中缝']]);
 // Navigation destinations must be direct children of a prototype section.
 const protoSection=figma.createSection();protoSection.name='10 / Photos prototype results';protoSection.x=13800;protoSection.y=0;
 const prototypes={};
 for(const [key,source] of Object.entries(made)){const copy=source.clone();copy.name='Save prototype / '+key;protoSection.appendChild(copy);prototypes[key]=copy;}
 const successFold=[];
 for(const [key,source]of [['duo-outer',outer],['duo-inner',inner],['duo-book',book]]){
   for(const destination of ['photos','files','both']){
     const copy=source.clone();copy.name='Save prototype / '+key+'-saved-'+destination;protoSection.appendChild(copy);
     const sh=copy.findOne(n=>n.name==='Export sheet / fold-aware');for(const n of [...sh.children])n.remove();
     icon(sh,'check_circle','success',40);text(sh,destination==='photos'?'已保存到相册':destination==='files'?'已保存到文件':'已保存到相册和文件',22,'ink','Bold',sh.width-40);
     notes(sh,'海岸漫步-edited.png');notes(sh,'原图保留，你可以继续编辑。');
     if(destination!=='both')button(sh,destination==='photos'?'保存到文件':'保存到相册',sh.width-40,'Secondary');
     button(sh,'继续编辑',sh.width-40);sh.y=(copy.height-sh.height)/2;
     prototypes[key+'-saved-'+destination]=copy;
     if(destination==='photos'){const design=copy.clone();made[key+'-saved-photos']=design;report.created[key+'-saved-photos']=design.id;successFold.push([design,key+' · 已存相册']);}
   }
 }
 rowScreens('04 / 折叠屏完成后仍保留当前姿态',successFold);
 for(const [key,s]of Object.entries(prototypes)){
   const pose=key.startsWith('duo-outer')?'duo-outer':key.startsWith('duo-inner')?'duo-inner':key.startsWith('duo-book')?'duo-book':null;
   const prefix=pose||'phone';
   for(const b of s.findAll(n=>n.type==='INSTANCE'&&n.name.startsWith('Button /'))){
     const label=b.findOne(n=>n.type==='TEXT')?.characters;
     if(label?.startsWith('保存到相册')&&key!=='phone-webp')await nav(b,prototypes[key.includes('saved-files')?prefix+'-saved-both':prefix+'-saved-photos']);
     if(label?.startsWith('保存到文件'))await nav(b,prototypes[key.includes('saved-photos')?prefix+'-saved-both':prefix+'-saved-files']);
     if(label==='打开系统设置')await nav(b,prototypes['phone-png']);
     if(label==='继续编辑'&&pose)await nav(b,await figma.getNodeByIdAsync(pose==='duo-outer'?'21:14899':pose==='duo-book'?'21:17818':'21:15024'));
   }
 }
 for(const [key,s]of Object.entries(made)){
   for(const b of s.findAll(n=>n.type==='INSTANCE'&&n.name==='Button / 保存到相册'))if(key!=='phone-webp')await nav(b,prototypes[key.startsWith('duo-')?key.replace('-png','')+'-saved-photos':'phone-saved-photos']||prototypes['phone-saved-photos']);
   for(const b of s.findAll(n=>n.type==='INSTANCE'&&n.name==='Button / 保存到文件'))await nav(b,prototypes[key.startsWith('duo-')?key.replace('-png','')+'-saved-files':'phone-saved-files']||prototypes['phone-saved-files']);
 }
 report.prototypes=Object.fromEntries(Object.entries(prototypes).map(([k,n])=>[k,n.id]));
 // Enable Photos actions in existing PNG/JPEG prototypes without changing the file route.
 for(const item of report.updated.filter(x=>x.eligible)){
   const photo=await figma.getNodeByIdAsync(item.photo);const file=await figma.getNodeByIdAsync(item.file);
   const dest=(file.reactions[0]?.actions?.[0]||file.reactions[0]?.action)?.destinationId;
   if(dest){const prior=await figma.getNodeByIdAsync(dest);const success=prior.clone();success.name='Photos result / '+item.frame;
     const sec=page.findOne(n=>n.name==='10 / Photos prototype results')||figma.createSection();if(!sec.parent||sec.parent.type==='DOCUMENT')page.appendChild(sec);sec.name='10 / Photos prototype results';sec.x=13800;sec.y=0;
     sec.appendChild(success);const i=sec.children.length-1;success.x=32+(i%3)*500;success.y=32+Math.floor(i/3)*1000;sec.resizeWithoutConstraints(3160,Math.ceil(sec.children.length/3)*1000+32);
     changeText(success,'已保存到文件','已保存到相册');await nav(photo,success);
   } else await nav(photo,prototypes['phone-saved-photos']);
 }
 for(const [i,n]of protoSection.children.entries()){n.x=32+(i%3)*1040;n.y=32+Math.floor(i/3)*1000;}protoSection.resizeWithoutConstraints(3160,Math.ceil(protoSection.children.length/3)*1000+32);
 for(const [n,style]of styleAssignments)await n.setTextStyleIdAsync(style);
 figma.currentPage.selection=[phonePng,outer];figma.viewport.scrollAndZoomIntoView([phonePng]);
 board.setPluginData('saveDestinationsReport',JSON.stringify(report));
 const html='<body style="font:13px system-ui;padding:12px"><h3>Save destinations synchronized</h3><p>'+report.updated.length+' export actions updated; '+Object.keys(report.created).length+' new editable states.</p>'+Object.entries(report.created).map(([k,id])=>'<p>'+k+' '+id+'</p>').join('')+'<button id="download">Export review images</button><script>document.getElementById("download").onclick=()=>parent.postMessage({pluginMessage:{type:"export"}},"*");onmessage=e=>{let m=e.data.pluginMessage;if(m.type==="file"){let a=document.createElement("a");a.href=URL.createObjectURL(new Blob([new Uint8Array(m.data)],{type:m.mime}));a.download=m.name;a.click();}};</script></body>';
 figma.showUI(html,{width:520,height:560});
 figma.ui.onmessage=async m=>{if(m.type==='export'){for(const key of ['phone-png','phone-permission','phone-saved-photos','duo-outer-png','duo-inner-png','duo-book-png'])figma.ui.postMessage({type:'file',name:'save-'+key+'.png',mime:'image/png',data:Array.from(await made[key].exportAsync({format:'PNG',constraint:{type:'SCALE',value:1}}))});figma.ui.postMessage({type:'file',name:'save-destinations-ledger.json',mime:'application/json',data:Array.from(unescape(encodeURIComponent(JSON.stringify(report,null,2))),c=>c.charCodeAt(0))});}};
})().catch(e=>figma.showUI('<p>'+stage+' : '+String(e)+' '+e.stack+'</p>',{width:700,height:400}));
