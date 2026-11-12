(async()=>{
 const page=await figma.getNodeByIdAsync('13:606');await figma.setCurrentPageAsync(page);
 const board=await figma.getNodeByIdAsync('33:22895');const report=JSON.parse(board.getPluginData('importSources'));
 report.invalidDestinations=[];report.prototypeConnections=0;report.frames=[];
 for(const [key,id]of [...Object.entries(report.screens),...Object.entries(report.prototype)]){
  const screen=await figma.getNodeByIdAsync(id);const panel=screen.findOne(n=>n.name==='Import source / Photos and Files');
  report.frames.push({key,id,width:screen.width,height:screen.height,panel:{x:panel.x,y:panel.y,width:panel.width,height:panel.height},sources:panel.findAll(n=>n.type==='TEXT').map(n=>n.characters)});
  for(const n of screen.findAll(n=>'reactions'in n))for(const r of n.reactions)for(const a of r.actions||[])if(a.type==='NODE'&&a.destinationId){report.prototypeConnections++;const dest=await figma.getNodeByIdAsync(a.destinationId);if(!dest||!['SECTION','PAGE'].includes(dest.parent.type))report.invalidDestinations.push({node:n.id,target:a.destinationId});}
 }
 board.setPluginData('importSources',JSON.stringify(report));
 const book=await figma.getNodeByIdAsync(report.screens['duo-book']);figma.currentPage.selection=[book];figma.viewport.scrollAndZoomIntoView([book]);
 figma.showUI('<body style="font:13px system-ui;padding:18px"><h3>导入设计核对完成</h3><p>屏幕 '+Object.keys(report.screens).length+' · 原型 '+Object.keys(report.prototype).length+' · 连接 '+report.prototypeConnections+' · 无效目标 '+report.invalidDestinations.length+'</p><button id="save">保存导入清单</button><script>const report='+JSON.stringify(report)+';document.getElementById("save").onclick=()=>{const a=document.createElement("a");a.href=URL.createObjectURL(new Blob([JSON.stringify(report,null,2)],{type:"application/json"}));a.download="pictools-import-sources-ledger.json";a.click();};</script></body>',{width:500,height:230});
})().catch(e=>figma.showUI('<p>'+String(e)+'</p>',{width:600,height:240}));
