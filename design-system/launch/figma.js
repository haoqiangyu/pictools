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
 if(page.findOne(n=>n.name==='12 / Native launch · iOS + Android'))throw new Error('Launch board already exists; inspect before retrying');
 const report={screens:{},prototypes:{},created:[],rules:[]};
 const right=Math.max(...page.children.map(n=>n.x+n.width));
 const board=auto(page,'12 / Native launch · iOS + Android',1880,'VERTICAL',40,40,'bg');board.x=right+200;board.y=0;
 text(board,'Pictools / Native launch',36,'ink','Bold');text(board,'打开即开始',28,'ink','Bold');
 text(board,'暖白与深墨，延续工作台。只在系统准备应用时显示；首页首帧就绪即接管。',18,'muted','Regular',1800);
 const statusSource=(await figma.getNodeByIdAsync('18:1272')).children.find(n=>n.name==='Safe area / status');
 const section=figma.createSection();section.name='13 / Native launch prototype';section.x=board.x+board.width+200;section.y=0;
 async function example(parent,key,label,w,h,dark=false,target='19:5234',android=false){
  const spec=auto(parent,'Specimen / '+label,w,'VERTICAL',12);text(spec,label,16,'ink','Bold',w);
  const s=frame(spec,'Launch / '+key,w,h,'bg');s.cornerRadius=24;s.clipsContent=true;s.setExplicitVariableModeForCollection(colorCollection,dark?darkMode:lightMode);
  const brand=C.logo.createInstance();s.appendChild(brand);brand.name='Brand / native 96';brand.rescale(96/brand.width);brand.cornerRadius=21;brand.x=(w-96)/2;brand.y=(h-96)/2;
  // Status chrome is illustrative; the operating system renders it at runtime.
  if(statusSource&&h>w){const bar=statusSource.clone();s.appendChild(bar);bar.resize(w,bar.height);bar.x=0;bar.y=0;}
  const home=frame(s,'System home indicator / illustrative',android?108:128,4,'ink');home.cornerRadius=2;home.x=(w-home.width)/2;home.y=h-12;
  report.screens[key]=s.id;
  const p=s.clone();p.name='Launch prototype / '+key;section.appendChild(p);report.prototypes[key]=p.id;
  await nav(p,await figma.getNodeByIdAsync(target));
  const note=key.includes('android12')?'系统图标区域 288dp；96dp 标志完整位于 192dp 安全圆内。':key.includes('inner')?'图形固定 96pt，不随大屏放大；原生启动位置由系统窗口决定。':'96pt/dp 图形居中 · 原生启动窗口 · 首帧交接';
  text(spec,note,13,'muted','Regular',w);
  return s;
 }
 const first=auto(board,'01 / iOS and Android 11',1800,'VERTICAL',20);text(first,'01 / iOS · Android 11 及以前',24,'ink','Bold');
 const r1=auto(first,'Launch examples',1800,'HORIZONTAL',32);
 await example(r1,'ios-light','iOS · 浅色',390,844);await example(r1,'ios-dark','iOS · 深色',390,844,true);
 await example(r1,'android11-light','Android ≤ 11 · 浅色',390,844,false,'19:5234',true);await example(r1,'android11-dark','Android ≤ 11 · 深色',390,844,true,'19:5234',true);
 const second=auto(board,'02 / Android 12 system launch',1800,'VERTICAL',20);text(second,'02 / Android 12+ · 系统启动页',24,'ink','Bold');const r2=auto(second,'System launch examples',1800,'HORIZONTAL',32);
 await example(r2,'android12-light','Android 12+ · 浅色',390,844,false,'19:5234',true);await example(r2,'android12-dark','Android 12+ · 深色',390,844,true,'19:5234',true);
 const rules=auto(r2,'Mask and startup rules',700,'VERTICAL',24,24,'surface');radius(rules,16);text(rules,'安全区与启动规则',22,'ink','Bold');
 const diagram=frame(rules,'Android 12 icon mask / 1dp = 1px',288,288,'subtle');
 const safe=tracked(figma.createEllipse(),'192dp system mask');diagram.appendChild(safe);safe.resize(192,192);safe.x=48;safe.y=48;color(safe,'tint');safe.strokes=[paint('primary')];safe.strokeWeight=1;safe.dashPattern=[4,4];
 const b=C.logo.createInstance();diagram.appendChild(b);b.rescale(96/b.width);b.cornerRadius=21;b.x=96;b.y=96;
 text(rules,'288 × 288dp 透明容器\n192dp 系统裁切安全圆\n96 × 96dp 实际品牌图形',16,'ink','Regular',652);
 for(const str of ['启动背景跟随系统浅色 / 深色；应用内主题设置在首页生效。','系统启动 → Rust 与设置初始化 → Flutter 首页首帧。','不新增 Splash Activity、不叠加 Flutter 开屏路由、不固定等待、不显示虚构进度。','Android 12+ 的图标定位与进入 / 退出动效由系统管理；不承诺按折痕移动原生图标。'])text(rules,str,15,'muted','Regular',652);
 const third=auto(board,'03 / Resizable windows',1800,'VERTICAL',20);text(third,'03 / 窗口尺寸适配',24,'ink','Bold');const r3=auto(third,'Duo launch examples',1800,'HORIZONTAL',32);
 await example(r3,'duo-outer','Duo 外屏',394,626,false,'21:14848');await example(r3,'duo-inner','Duo 展开 · 原生窗口居中',951,669,true,'21:17818');
 const fourth=auto(board,'04 / Compact and landscape',1800,'VERTICAL',20);text(fourth,'04 / 小屏与横屏',24,'ink','Bold');const r4=auto(fourth,'Compact launch examples',1800,'HORIZONTAL',32);
 await example(r4,'small','紧凑手机',320,568);await example(r4,'landscape','横屏窗口',844,390,false);
 const handoff=auto(board,'05 / First frame handoff',1800,'VERTICAL',16);text(handoff,'05 / 首帧交接',24,'ink','Bold');text(handoff,'启动图形会随系统启动窗口退出；已初始化的工作台直接出现。点击右侧原型的启动页可查看交接目标，原型点击不代表产品需要点击。',15,'muted','Regular',1760);
 const home=(await figma.getNodeByIdAsync('19:5234')).clone();home.name='Launch handoff / interactive home';handoff.appendChild(home);
 for(const [i,p]of section.children.entries()){p.x=32+(i%3)*1040;p.y=32+Math.floor(i/3)*1000;}section.resizeWithoutConstraints(3160,Math.ceil(section.children.length/3)*1000+32);
 for(const [n,style]of styleAssignments)await n.setTextStyleIdAsync(style);
 report.boardId=board.id;report.prototypeSection=section.id;report.created=ledger.createdNodeIds;report.brandComponent=C.logo.id;report.bounds={x:board.x,y:board.y,width:board.width,height:board.height};
 report.invalidTargets=[];report.connections=0;for(const n of section.findAll(n=>'reactions'in n))for(const r of n.reactions)for(const a of r.actions||[])if(a.type==='NODE'&&a.destinationId){report.connections++;const target=await figma.getNodeByIdAsync(a.destinationId);if(!target||!['SECTION','PAGE'].includes(target.parent.type))report.invalidTargets.push(a.destinationId);}
 board.setPluginData('nativeLaunch',JSON.stringify(report));
 figma.currentPage.selection=[second];figma.viewport.scrollAndZoomIntoView([second]);
 figma.showUI('<body style="font:13px system-ui;padding:18px"><h3>原生启动页已同步</h3><p>10 个可编辑尺寸 / 模式示例 · '+report.connections+' 个原型连接 · 无效目标 '+report.invalidTargets.length+'</p><p>画板 '+board.id+'</p><button id="save">保存开屏清单</button><script>const report='+JSON.stringify(report)+';document.getElementById("save").onclick=()=>{const a=document.createElement("a");a.href=URL.createObjectURL(new Blob([JSON.stringify(report,null,2)],{type:"application/json"}));a.download="pictools-native-launch-ledger.json";a.click();};</script></body>',{width:500,height:250});
})().catch(e=>figma.showUI('<p>'+stage+' '+String(e)+'</p>',{width:650,height:300}));
