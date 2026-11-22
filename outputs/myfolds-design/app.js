'use strict';

const $ = (s,root=document)=>root.querySelector(s);
const $$ = (s,root=document)=>[...root.querySelectorAll(s)];
const esc = value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const icon = name=>`<span class="icon sf-symbol" style="--symbol:url('assets/symbols/${name}.png')" aria-hidden="true"></span>`;
const paintIcons=()=>$$('[data-icon]').forEach(el=>{el.innerHTML=icon(el.dataset.icon)});
const ROOT='/Users/demo/Pictures/旅途精选', OUT=ROOT+'/导出', ZIP='/Users/demo/Downloads/旅行素材.7z', ARCH='archive:'+ZIP;
const folder=(id,name,target,count=0)=>({id,name,type:'folder',kind:'文件夹',size:'—',date:'今天 10:24',target,count});
const originals = [
  folder('raw','原始素材',ROOT+'/原始素材',4),folder('exports','导出',OUT,1),
  {id:'mountain',name:'山野暮色.jpg',type:'image',kind:'JPEG 图像',size:'8.4 MB',date:'今天 10:42',image:'assets/mountain.jpg',dimensions:'3840 × 2560',color:'Display P3',tag:'精选'},
  {id:'coast',name:'海岸线.jpg',type:'image',kind:'JPEG 图像',size:'5.2 MB',date:'今天 10:38',image:'assets/coast.jpg',dimensions:'3840 × 2560',color:'sRGB'},
  {id:'forest',name:'森林光影.heic',type:'image',kind:'HEIF 图像',size:'4.1 MB',date:'今天 10:35',image:'assets/forest.jpg',dimensions:'4032 × 3024',color:'Display P3'},
  {id:'flower',name:'花园片段.mp4',type:'video',kind:'MP4 视频',size:'24.6 MB',date:'今天 09:51',image:'assets/flower.jpg',video:'assets/flower.mp4',dimensions:'960 × 540',duration:'00:05',codec:'H.264 / AAC'},
  {id:'mkv',name:'旅行短片.mkv',type:'unsupported',kind:'MKV 视频',size:'1.2 GB',date:'昨天 21:18',dimensions:'3840 × 2160',duration:'08:32'},
  {id:'archive',name:'旅行素材.7z',type:'archive',kind:'7z 压缩包',size:'186 MB',date:'昨天 19:42',target:ARCH},
  {id:'notes',name:'拍摄清单.md',type:'text',kind:'Markdown',size:'2 KB',date:'昨天 18:03',text:'# 旅途精选\n\n- 山野暮色\n- 海岸线\n- 森林光影\n\n待办\n[ ] 挑选照片\n[ ] 导出分享版本'},
  {id:'pdf',name:'行程参考.pdf',type:'document',kind:'PDF 文稿',size:'1.8 MB',date:'11月18日 12:06'}
];
function seedDirectories(){
 const dirs={}; dirs[ROOT]=structuredClone(originals);
 dirs[OUT]=[{...structuredClone(originals[2]),id:'old-mountain',size:'3.2 MB',date:'昨天 16:20'}];
 dirs[ROOT+'/原始素材']=structuredClone(originals.filter(f=>['mountain','coast','forest','flower'].includes(f.id))).map(f=>({...f,id:'raw-'+f.id}));
 dirs['/Users/demo/Downloads']=[{...structuredClone(originals[7]),id:'download-archive'}, {...structuredClone(originals[3]),id:'download-coast'},folder('installers','安装包','/Users/demo/Downloads/安装包',0)];
 dirs['/Users/demo/Downloads/安装包']=[];
 dirs['/Users/demo/Pictures']=[folder('trip','旅途精选',ROOT,10)];
 dirs['/Users/demo/Documents']=[{...structuredClone(originals[8]),id:'doc-notes'},{...structuredClone(originals[9]),id:'doc-pdf'}];
 dirs['/Users/demo/Desktop']=[]; dirs['/Users/demo/Projects']=[folder('design','设计资料','/Users/demo/Projects/设计资料')]; dirs['/Users/demo/Projects/设计资料']=[];
 dirs['/Users/demo/Recent']=structuredClone(originals.slice(2,6)).map(f=>({...f,id:'recent-'+f.id}));
 dirs['/Users/demo']=[folder('pictures','图片','/Users/demo/Pictures',1),folder('downloads','下载','/Users/demo/Downloads',3),folder('documents','文稿','/Users/demo/Documents',2),folder('desktop','桌面','/Users/demo/Desktop')];
 dirs['/Users']=[folder('demo-user','demo','/Users/demo',4)]; dirs['/']=[folder('users','Users','/Users',1),folder('volumes','Volumes','/Volumes',1)];dirs['/Volumes']=[folder('external','工作硬盘','/Volumes/工作硬盘')];
 dirs[ARCH]=[folder('zip-images','照片',ARCH+'/照片',3),folder('zip-video','视频',ARCH+'/视频',1),{...structuredClone(originals[8]),id:'zip-notes',name:'README.md'}];
 dirs[ARCH+'/照片']=structuredClone(originals.filter(f=>f.type==='image')).map(f=>({...f,id:'zip-'+f.id})); dirs[ARCH+'/视频']=[{...structuredClone(originals[5]),id:'zip-flower'}];
 dirs['trash:']=[];return dirs;
}
let dirs=seedDirectories();
const state={paths:[ROOT,OUT],active:0,selected:new Set(),split:false,preview:false,view:'list',query:'',sort:'name',ascending:true,clipboard:null,task:null,scene:'browse',error:null,defaults:{jpg:'内置预览',heic:'内置预览',mp4:'内置预览'},history:[],undo:null,mediaId:null,zoom:false,externalConnected:true,forcedState:null,tabs:[{id:'tab-1',path:ROOT}],activeTab:'tab-1'};
let taskTimer=null,toastTimer=null,loadingTimer=null,idCounter=0,lastRowClick={id:null,time:0};
let popoverReturnFocus=null,dialogReturnFocus=null,tabCounter=1;
const path=()=>state.paths[state.active];
const filesAt=(p=path())=>dirs[p]||[];
const selectedFiles=()=>filesAt().filter(f=>state.selected.has(f.id));
const firstSelected=()=>selectedFiles()[0];
const isArchive=(p=path())=>p.startsWith('archive:');
const offlinePath=(p=path())=>!state.externalConnected&&p.startsWith('/Volumes/工作硬盘');
const titleFor=p=>({'trash:':'废纸篓','/Users/demo':'个人文件','/Users/demo/Downloads':'下载','/Users/demo/Documents':'文稿','/Users/demo/Pictures':'图片','/Users/demo/Desktop':'桌面','/Users/demo/Recent':'最近使用','/Users/demo/Projects':'项目文件'})[p]||p.split('/').filter(Boolean).at(-1)||'Macintosh HD';
const shownPath=p=>p==='trash:'?'废纸篓':p.startsWith('archive:')?p.slice(8):p;
const ext=f=>f?.name.split('.').at(-1).toLowerCase();
const uid=()=>`copy-${++idCounter}`;
function nativeFileIcon(f){return f.type==='folder'?'folder-native':f.type==='archive'?'archive-native':['video','unsupported'].includes(f.type)?'movie-native':ext(f)==='pdf'?'pdf-native':'text-native'}
function thumbnail(f){if(f.image)return `<img class="file-thumb" src="${f.image}" alt="" loading="lazy">`;return `<span class="file-icon ${f.type}"><img src="assets/${nativeFileIcon(f)}.png" alt=""></span>`}
function shortKind(f){return({folder:'文件夹',image:ext(f).toUpperCase(),video:'视频',unsupported:'视频',archive:'压缩包',text:'文稿',document:'文稿'})[f.type]||f.kind}
function sizeValue(value){const n=parseFloat(value)||0;return n*(value.includes('GB')?1e9:value.includes('MB')?1e6:value.includes('KB')?1e3:1)}
function dateValue(value){const day=value.startsWith('刚刚')?21:value.startsWith('今天')?20:value.startsWith('昨天')?19:18;const time=value.match(/(\d{2}):(\d{2})/);return day*1440+(time?Number(time[1])*60+Number(time[2]):0)}
function visibleFiles(p){let list=[...filesAt(p)];if(p===path()&&state.query)list=list.filter(f=>f.name.toLowerCase().includes(state.query.toLowerCase()));let field=state.sort==='date'?'date':state.sort==='type'?'kind':state.sort==='size'?'size':'name';list.sort((a,b)=>{if(a.type==='folder'&&b.type!=='folder')return -1;if(b.type==='folder'&&a.type!=='folder')return 1;const av=field==='size'?sizeValue(a.size):field==='date'?dateValue(a.date):String(a[field]),bv=field==='size'?sizeValue(b.size):field==='date'?dateValue(b.date):String(b[field]);return (typeof av==='number'?av-bv:av.localeCompare(bv,'zh-CN',{numeric:true}))*(state.ascending?1:-1)});return list}
function renderPane(pane){
 const p=state.paths[pane],active=pane===state.active,items=visibleFiles(p),container=$(pane?'#target-pane':'#main-pane');
 container.classList.toggle('active-pane',active);container.dataset.pane=String(pane);container.dataset.path=p;container.dataset.query=active?state.query:'';container.tabIndex=-1;
 const focusId=$('[data-id]:focus',container)?.dataset.id||(active?items.find(f=>state.selected.has(f.id))?.id:null)||items[0]?.id;
 let head=`<div class="pane-heading"><h${pane?'2':'1'}>${esc(titleFor(p))}</h${pane?'2':'1'}>${isArchive(p)?'<span class="archive-tag">压缩包 · 只读</span>':`<small>${filesAt(p).length} 项</small>`}${state.split?`<span class="pane-target-tag">${active?'当前操作位置':'点击切换'}</span>`:''}<button class="icon-button" data-action="sort" data-pane="${pane}" aria-label="排序选项" title="排序选项">${icon('sort')}</button></div>`;
 if(state.split)head+=`<div class="pane-path" title="${esc(shownPath(p))}">${esc(shownPath(p))}</div>`;
 if(isArchive(p))head+=`<div class="archive-banner">${icon('archive')}<span>先查看内容，再提取需要的文件</span><button class="button" data-action="extract">${state.selected.size?'解压所选':'全部解压'}</button></div>`;
 let body='';
 const forced=active?state.forcedState:null;
 if(offlinePath(p)||forced==='disconnected')body=emptyHTML('external','工作硬盘已断开','重新连接硬盘后重试。未完成的移动不会被标记为成功。','重新连接并重试','reconnect');
 else if((p==='/Volumes/工作硬盘'&&!(p in dirs))||forced==='denied')body=emptyHTML('lock','需要访问此文件夹的权限','选择文件夹以授权访问。授权后回到当前位置继续。','授权访问','authorize');
 else if(forced==='loading')body=emptyHTML('refresh','正在读取文件夹','正在加载名称与基本信息，缩略图随后显示。','取消读取','cancel-loading','spin');
 else if(!items.length||forced==='empty')body=emptyHTML(state.query?'search':'folder',state.query?'没有匹配的文件':'此文件夹为空',state.query?`没有名称包含“${state.query}”的文件。试试其他关键词。`:'可以将文件粘贴到这里，或新建文件夹。',state.query?'清除搜索':'新建文件夹',state.query?'clear-search':'new-folder');
 else if(state.view==='grid')body=`<div class="files-scroll"><div class="grid-files" role="listbox" aria-label="${esc(titleFor(p))}中的文件" aria-multiselectable="true">${items.map(f=>`<div class="file-card ${active&&state.selected.has(f.id)?'selected':''} ${state.clipboard?.mode==='cut'&&state.clipboard.source===p&&state.clipboard.ids.includes(f.id)?'cut':''}" tabindex="${f.id===focusId?0:-1}" role="option" aria-selected="${active&&state.selected.has(f.id)}" data-id="${f.id}" data-pane="${pane}" title="${esc(f.name)}">${thumbnail(f)}${state.clipboard?.mode==='cut'&&state.clipboard.source===p&&state.clipboard.ids.includes(f.id)?`<span class="cut-indicator" aria-label="等待移动" title="等待移动">${icon('scissors')}</span>`:''}<span class="file-name">${esc(f.name)}</span><small>${f.size==='—'?'文件夹':f.size}</small></div>`).join('')}</div></div>`;
 else body=`<div class="files-scroll"><table class="file-table" role="grid" aria-label="${esc(titleFor(p))}中的文件" aria-multiselectable="true"><thead><tr><th class="name-column"><button data-sort="name">名称 ${icon('chevronDown')}</button></th><th class="date-column"><button data-sort="date">修改日期</button></th><th class="type-column"><button data-sort="type">类型</button></th><th class="size-column"><button data-sort="size">大小</button></th></tr></thead><tbody>${items.map(f=>{const cut=state.clipboard?.mode==='cut'&&state.clipboard.source===p&&state.clipboard.ids.includes(f.id);return `<tr class="file-row ${active&&state.selected.has(f.id)?'selected':''} ${cut?'cut':''}" tabindex="${f.id===focusId?0:-1}" aria-selected="${active&&state.selected.has(f.id)}" data-id="${f.id}" data-pane="${pane}" title="${esc(f.name)}"><td><span class="name-cell">${thumbnail(f)}<span class="file-name">${esc(f.name)}</span>${cut?`<span class="cut-indicator" title="等待移动">${icon('scissors')}</span>`:''}</span></td><td class="date-column">${f.date}</td><td class="type-column">${shortKind(f)}</td><td class="size-column">${f.size}</td></tr>`}).join('')}</tbody></table></div>`;
 container.innerHTML=head+body;
}
function emptyHTML(symbol,title,description,button,action,extra=''){return `<div class="empty-state"><span class="${extra}">${icon(symbol)}</span><h3>${esc(title)}</h3><p>${esc(description)}</p><button class="button" data-action="${action}">${esc(button)}</button></div>`}
function captureTab(){
 const tab=state.tabs.find(t=>t.id===state.activeTab);if(!tab)return;
 Object.assign(tab,{path:state.paths[0],paths:[...state.paths],active:state.active,selected:[...state.selected],view:state.view,query:state.query,preview:state.preview,split:state.split,history:structuredClone(state.history),sort:state.sort,ascending:state.ascending,scroll:$$('.file-pane').map(p=>$('.files-scroll',p)?.scrollTop||0)});
}
function renderTabs(){
 const current=state.tabs.find(t=>t.id===state.activeTab);if(current)current.path=state.paths[0];
 $('#tabs-row').hidden=state.tabs.length<2;
 $('.tabs').innerHTML=state.tabs.map(t=>`<div class="tab-item ${t.id===state.activeTab?'active':''}"><button class="tab" role="tab" id="${t.id}" aria-selected="${t.id===state.activeTab}" aria-controls="main-pane" tabindex="${t.id===state.activeTab?0:-1}" data-tab="${t.id}" title="${esc(shownPath(t.path))}">${icon('folder')}<span>${esc(titleFor(t.path))}</span></button><button class="icon-button tab-close" data-close-tab="${t.id}" aria-label="关闭标签页 ${esc(titleFor(t.path))}" title="关闭标签页">${icon('close')}</button></div>`).join('');
}
function activateTab(id,save=true){
 const tab=state.tabs.find(t=>t.id===id);if(!tab)return;if(save)captureTab();
 hidePopover();closePath();state.activeTab=id;state.paths=[...(tab.paths||[tab.path,OUT])];state.active=tab.active||0;state.selected=new Set(tab.selected||[]);state.view=tab.view||'list';state.query=tab.query||'';state.preview=tab.preview||false;state.split=tab.split||false;state.history=structuredClone(tab.history||[]);state.sort=tab.sort||'name';state.ascending=tab.ascending!==false;state.forcedState=null;render();
 $$('.file-pane').forEach((p,i)=>{const scroll=$('.files-scroll',p);if(scroll){scroll.scrollTop=tab.scroll?.[i]||0;syncListHeader(scroll)}});
 document.getElementById(id)?.focus({preventScroll:true});
}
function addTab(){captureTab();const id='tab-'+(++tabCounter);state.tabs.push({id,path:'/Users/demo',paths:['/Users/demo',OUT]});activateTab(id,false)}
function closeTab(id){
 if(state.tabs.length<2)return;const index=state.tabs.findIndex(t=>t.id===id);if(index<0)return;
 if(id===state.activeTab){state.tabs.splice(index,1);activateTab(state.tabs[Math.min(index,state.tabs.length-1)].id,false)}else{state.tabs.splice(index,1);renderTabs()}
 if(state.tabs.length===1)$('#main-pane').focus({preventScroll:true});
}
function renderInspector(){
 const area=$('#inspector'),sel=selectedFiles(),f=sel[0];
 if(sel.length!==1){area.innerHTML=`<div class="inspector-header"><span>${sel.length?'所选项目':'文件夹信息'}</span><button class="icon-button" data-action="preview-toggle" aria-label="关闭预览区" title="关闭预览区">${icon('close')}</button></div><div class="inspector-empty"><div class="folder-summary"><img src="assets/${sel.length?'text-native':'folder-native'}.png" alt=""><div><strong>${sel.length?`已选择 ${sel.length} 项`:esc(titleFor(path()))}</strong><span>${sel.length?'可复制或剪切':filesAt().length+' 个项目'}</span></div></div><dl class="metadata"><dt>位置</dt><dd class="path-value">${esc(shownPath(path()))}</dd></dl><p>${sel.length?'选择单个文件以查看预览与详细信息。':'选择文件后，这里会显示预览与详细信息。'}</p></div>`;return}
 let preview='';
 if(f.image)preview=`<button class="preview-photo" data-action="quick-look" aria-label="放大预览 ${esc(f.name)}"><img src="${f.image}" alt="${esc(f.name)} 的示例预览">${f.type==='video'?`<span class="play-overlay">${icon('play')}</span><span class="duration">${f.duration}</span>`:''}<span class="expand-overlay">${icon('expand')}</span></button>`;
 else if(f.type==='text')preview=`<div class="text-preview">${esc(f.text)}</div>`;
 else preview=`<div class="generic-preview ${f.type}">${`<img src="assets/${nativeFileIcon(f)}.png" alt="">`}</div>`;
 const primary=f.type==='folder'?'打开文件夹':f.type==='archive'?'浏览压缩包':'打开';
 area.innerHTML=`<div class="inspector-header"><span>预览</span><button class="icon-button" data-action="quick-look" aria-label="放大预览" title="放大预览 空格">${icon('expand')}</button></div>${preview}<h2>${esc(f.name)}</h2><p class="file-subtitle">${f.kind} ${f.size!=='—'?'· '+f.size:''}</p><div class="preview-actions"><button class="button" data-action="open-file">${icon(f.type==='archive'?'archive':'arrowUpRight')}${primary}</button>${!['folder','archive'].includes(f.type)?`<button class="button" data-action="open-with">打开方式 ${icon('chevronDown')}</button>`:''}</div><dl class="metadata"><dt>大小</dt><dd>${f.size}</dd>${f.dimensions?`<dt>尺寸</dt><dd>${f.dimensions}</dd>`:''}${f.duration?`<dt>时长</dt><dd>${f.duration}</dd>`:''}${f.color?`<dt>色彩空间</dt><dd>${f.color}</dd>`:''}${f.codec?`<dt>编码</dt><dd>${f.codec}</dd>`:''}<dt>修改时间</dt><dd>${f.date}</dd><dt>所在位置</dt><dd class="path-value">${esc(shownPath(path()))}</dd></dl>${f.tag?`<div class="tag-row"><span class="tag-label"><i class="tag-dot"></i>${f.tag}</span></div>`:''}<div class="preview-footnote"><span>${f.type==='archive'?'打开即可浏览包内文件':f.type==='folder'?'双击进入文件夹':'空格键快速查看'}</span>${!['folder','archive'].includes(f.type)?'<kbd>Space</kbd>':''}</div>`;
}
function rememberFocus(element=document.activeElement){
 if(element?.closest('#popover'))return popoverReturnFocus;
 const file=element?.closest('[data-id]');
 return {element,id:element?.id,fileId:file?.dataset.id,pane:file?.dataset.pane,path:file?.closest('.file-pane')?.dataset.path,action:element?.dataset.action,area:element?.closest('#inspector,#task-shelf,#clipboard-shelf')?.id};
}
function restoreFocus(saved){
 if(!saved)return;
 let element=saved.element?.isConnected?saved.element:null;
 if(!element&&saved.fileId){const pane=$(`.file-pane[data-pane="${saved.pane}"]`);if(pane?.dataset.path===saved.path)element=$(`[data-id="${CSS.escape(saved.fileId)}"]`,pane)}
 if(!element&&saved.id)element=document.getElementById(saved.id);
 if(!element&&saved.action&&saved.area)element=$(`#${saved.area} [data-action="${saved.action}"]`);
 if(element&&element.checkVisibility()&&!element.disabled)element.focus({preventScroll:true});
}
function focusFile(id,pane=state.active,scroll=false){
 const container=$(pane?'#target-pane':'#main-pane');
 if(!id){container.focus({preventScroll:true});return}
 $$('[data-id]',container).forEach(el=>el.tabIndex=el.dataset.id===id?0:-1);
 const file=$(`[data-id="${CSS.escape(id)}"]`,container);
 file?.focus({preventScroll:true});if(scroll)file?.scrollIntoView({block:'nearest',inline:'nearest'});
}
function render(){
 const focused=rememberFocus();
 const scrolls=$$('.file-pane').map(pane=>({pane,path:pane.dataset.path,query:pane.dataset.query,top:$('.files-scroll',pane)?.scrollTop||0}));
 $('#window-folder-title').textContent=titleFor(path());$('#path-text').textContent=shownPath(path());$('#address-display').title=shownPath(path());$('#search-input').value=state.query;
 $('#back-button').disabled=!state.history.length;$('#target-pane').hidden=!state.split;
 $('#content-area').classList.toggle('split-mode',state.split);$('#inspector').hidden=!state.preview||state.split;
 $('#split-button').classList.toggle('selected',state.split);$('#split-button').setAttribute('aria-pressed',state.split);
 $('#preview-button').classList.toggle('selected',state.preview&&!state.split);$('#preview-button').setAttribute('aria-pressed',state.preview&&!state.split);
 for(const v of ['list','grid']){$(`#${v}-button`).classList.toggle('selected',state.view===v);$(`#${v}-button`).setAttribute('aria-pressed',state.view===v)}
 renderPane(0);if(state.split)renderPane(1);renderInspector();renderTabs();
 const chosen=selectedFiles();$('#cut-button').disabled=!chosen.length||isArchive()||!!state.task?.running;$('#copy-button').disabled=!chosen.length||!!state.task?.running;$('#paste-button').disabled=!state.clipboard||isArchive()||offlinePath()||!!state.task?.running;$$('[data-action="new-folder"]').forEach(el=>el.disabled=isArchive()||offlinePath());
 $('#status-text').textContent=`${visibleFiles(path()).length} 个项目${chosen.length?` · 已选择 ${chosen.length} 项${chosen.length===1&&chosen[0].size!=='—'?' · '+chosen[0].size:''}`:''}`;
 if(offlinePath())$('#status-text').textContent='设备不可用';
 $('#status-right').textContent=offlinePath()?'工作硬盘已断开':path().startsWith('/Volumes/工作硬盘')?'工作硬盘 · 已连接':isArchive()?'压缩包只读浏览':'';
 $('.status-dot').classList.toggle('offline',offlinePath());
 const device=$('#external-device');device.classList.toggle('offline',!state.externalConnected);device.setAttribute('aria-label',state.externalConnected?'工作硬盘':'工作硬盘，已断开');$('.device-state',device).hidden=state.externalConnected;
 $$('[data-folder]').forEach(el=>{const active=el.dataset.folder===(el.getAttribute('role')==='tab'?state.paths[0]:path());el.classList.toggle('active',active);if(el.getAttribute('role')==='tab')el.setAttribute('aria-selected',active)});
 renderClipboard();renderTask();
 for(const saved of scrolls){const scroller=$('.files-scroll',saved.pane);if(scroller&&saved.path===saved.pane.dataset.path&&saved.query===saved.pane.dataset.query){scroller.scrollTop=saved.top;syncListHeader(scroller)}}
 restoreFocus(focused);
}
function renderClipboard(){const c=state.clipboard,el=$('#clipboard-shelf');el.hidden=!c||!!state.task?.running;if(!c)return;const noun=c.mode==='cut'?'移动':'复制';el.innerHTML=`<span class="shelf-icon">${icon(c.mode==='cut'?'scissors':'copy')}</span><div><strong>${c.ids.length} 项等待${noun}</strong><small>来源：${esc(titleFor(c.source))} · ${c.mode==='cut'?'粘贴成功前保留源文件':'源文件保留'}</small></div><div class="shelf-controls"><button class="icon-button" data-action="cancel-clipboard" aria-label="取消${noun}" title="取消${noun}">${icon('close')}</button><button class="button primary" data-action="paste" ${isArchive()||offlinePath()?'disabled':''}>${noun}到${esc(titleFor(path()))}</button></div>`}
function renderTask(){const focused=rememberFocus();const t=state.task,el=$('#task-shelf');el.hidden=!t;$('#task-count').textContent=t?.running?'1 个任务':'任务';if(!t)return;el.innerHTML=`<div class="task-summary ${t.running?'':'complete'}">${icon(t.running?'activity':t.cancelled?'undo':'checkCircle')}<strong>${esc(t.title)}</strong><span>${t.running?t.progress+'%':t.cancelled?'已取消':'已完成'}</span>${t.running?'<button class="icon-button" data-action="cancel-task" title="取消任务" aria-label="取消任务">'+icon('close')+'</button>':'<button class="icon-button" data-action="dismiss-task" title="收起任务" aria-label="收起任务">'+icon('close')+'</button>'}</div>${t.running?`<div class="progress-track"><i style="width:${t.progress}%"></i></div>`:''}<div class="task-caption">${esc(t.detail)}${!t.running&&!t.cancelled&&state.undo?' <button class="text-link" data-action="undo">撤销</button>':''}</div>`;restoreFocus(focused)}
function notify(message,symbol='check'){clearTimeout(toastTimer);const el=$('#toast');el.innerHTML=icon(symbol)+`<span>${esc(message)}</span>`;el.hidden=false;toastTimer=setTimeout(()=>el.hidden=true,3600)}
function hidePopover(restore=false){const wasOpen=!$('#popover').hidden;$('#popover').hidden=true;if(restore&&wasOpen)restoreFocus(popoverReturnFocus)}
function closePath(restore=false){const wasOpen=!$('#address-form').hidden;$('#address-form').hidden=true;$('#address-display').hidden=false;$('#path-suggestions').hidden=true;if(restore&&wasOpen)$('#address-display').focus({preventScroll:true})}
function navigate(next,{pane=state.active,record=true}={}){
 hidePopover();closePath();$('.app-window').classList.remove('sidebar-open');state.forcedState=null;clearTimeout(loadingTimer);
 next=next.trim().replace(/^file:\/\//,'').replace(/^~(?=\/|$)/,'/Users/demo').replace(/\/$/,'')||'/';
 if(!(next in dirs)&&next!=='/Volumes/工作硬盘'){
   const slash=next.lastIndexOf('/'),parent=next.slice(0,slash)||'/',name=next.slice(slash+1),file=filesAt(parent).find(f=>f.name===name);
   if(file){navigate(parent,{pane,record});state.selected=new Set([file.id]);render();return true}
   editPath(next);$('#path-suggestions').innerHTML=`<div class="path-error">找不到这个路径<p>原型支持示例目录，例如 ~/Downloads 或 ~/Pictures/旅途精选。</p></div>`;return false;
 }
 if(record)state.history.push({path:state.paths[pane],pane});state.active=pane;state.paths[pane]=next;state.selected=new Set();state.query='';render();return true;
}
function parentPath(p){if(p==='trash:')return ROOT;if(p===ARCH)return '/Users/demo/Downloads';if(p==='/')return '/';const parent=p.slice(0,p.lastIndexOf('/'));return parent||'/'}
function editPath(value=shownPath(path())){$('#address-display').hidden=true;$('#address-form').hidden=false;const input=$('#path-input');input.value=value;showSuggestions(value);input.focus();input.select()}
function showSuggestions(value){const candidates=[ROOT,OUT,'/Users/demo/Downloads','/Users/demo/Documents','/Users/demo/Pictures','/Users/demo/Desktop','/Users/demo/Projects'];const q=value.replace(/^~/,'/Users/demo').toLowerCase();let matches=candidates.filter(x=>x.toLowerCase().includes(q));if(!matches.length)matches=candidates.slice(0,4);const el=$('#path-suggestions');el.innerHTML=`<div class="suggestion-heading">常用与最近访问</div>${matches.slice(0,5).map(p=>`<button class="suggestion" data-goto="${esc(p)}">${icon('folder')}<span><strong>${esc(titleFor(p))}</strong><small>${esc(p)}</small></span></button>`).join('')}`;el.hidden=false}
function selectFile(id,pane,event={}){if(state.active!==pane){state.active=pane;state.selected=new Set()}if(event.metaKey||event.ctrlKey){state.selected.has(id)?state.selected.delete(id):state.selected.add(id)}else if(event.shiftKey&&state.selected.size){const list=visibleFiles(path()),from=list.findIndex(f=>f.id===[...state.selected][0]),to=list.findIndex(f=>f.id===id);state.selected=new Set(list.slice(Math.min(from,to),Math.max(from,to)+1).map(f=>f.id))}else state.selected=new Set([id]);render();focusFile(id,pane)}
function clipboard(mode){const selected=selectedFiles();if(!selected.length)return;if(isArchive()){if(mode==='cut')notify('压缩包为只读，请使用解压操作','lock');else extractDialog();return}state.clipboard={mode,source:path(),ids:selected.map(f=>f.id),files:structuredClone(selected)};state.task=null;render()}
function snapshot(){return {dirs:structuredClone(dirs),paths:[...state.paths]}}
function uniqueName(name,target){const index=name.lastIndexOf('.'),stem=index>0?name.slice(0,index):name,ending=index>0?name.slice(index):'';let n=2,candidate=`${stem} (${n})${ending}`;while(filesAt(target).some(f=>f.name===candidate)){n++;candidate=`${stem} (${n})${ending}`}return candidate}
function copyEntry(source,target,name=source.name){const copy={...structuredClone(source),id:uid(),name,date:'刚刚'};if(source.type==='folder'){copy.target=target+'/'+name;dirs[copy.target]=[];for(const child of filesAt(source.target))dirs[copy.target].push(copyEntry(child,copy.target))}return copy}
function paste(resolution){if(offlinePath())return notify('工作硬盘已断开，请重新连接后继续','external');const c=state.clipboard;if(!c||state.task?.running)return;if(isArchive())return notify('压缩包为只读，请选择普通文件夹','lock');const target=path();if(c.mode==='cut'&&c.source===target)return notify('请先前往目标文件夹，再粘贴','warning');if(c.files.some(f=>f.type==='folder'&&(target===f.target||target.startsWith(f.target+'/'))))return notify('不能将文件夹移入它自己或其子文件夹','warning');const conflict=c.files.find(f=>filesAt(target).some(x=>x.name===f.name));if(conflict&&!resolution){conflictDialog(conflict,filesAt(target).find(x=>x.name===conflict.name));return}
 const before=snapshot();const noun=c.mode==='cut'?'移动':'复制';startTask(`${noun} ${c.files.length} 项`,`${titleFor(c.source)} → ${titleFor(target)}`,()=>{
  const moved=[];for(const f of c.files){const existing=filesAt(target).find(x=>x.name===f.name);if(existing&&resolution==='skip')continue;let name=f.name;if(existing&&resolution==='keep')name=uniqueName(f.name,target);if(existing&&resolution==='replace')dirs[target]=filesAt(target).filter(x=>x.id!==existing.id);const added=copyEntry(f,target,name);dirs[target].push(added);moved.push({old:f.id,id:added.id})}
  if(c.mode==='cut'){dirs[c.source]=filesAt(c.source).filter(f=>!moved.some(m=>m.old===f.id));state.clipboard=null}state.undo=before;state.selected=new Set(moved.map(m=>m.id));return {title:`已${noun} ${moved.length} 项`,detail:`目标：${shownPath(target)}${resolution==='keep'?' · 同名文件已保留两份':''}${resolution==='skip'?' · 已跳过同名文件':''}`};
 });
}
function startTask(title,detail,commit){clearInterval(taskTimer);state.task={title,detail,progress:0,running:true};render();taskTimer=setInterval(()=>{if(!state.task?.running){clearInterval(taskTimer);return}state.task.progress=Math.min(100,state.task.progress+20);if(state.task.progress===100){clearInterval(taskTimer);const result=commit();state.task={...state.task,...result,running:false};render()}else renderTask()},420)}
function cancelTask(){clearInterval(taskTimer);state.task={title:'操作已取消',detail:'示例文件未发生变化，源文件仍在原位置。',running:false,cancelled:true};render()}
function openDialog(title,content,actions){const d=$('#dialog');if(!d.open)dialogReturnFocus=rememberFocus();hidePopover();closePath();d.className='';d.innerHTML=`<div class="dialog-header"><h2 id="dialog-title">${title}</h2><button class="icon-button" data-action="close-dialog" aria-label="关闭对话框">${icon('close')}</button></div><div class="dialog-content">${content}</div>${actions?`<div class="dialog-actions">${actions}</div>`:''}`;if(!d.open)d.showModal()}
const cancelButton='<button class="button" data-action="close-dialog">取消</button>';
function conflictDialog(incoming,existing){function item(f,label){return `<div class="conflict-file"><span>${label}</span>${f.image?`<img src="${f.image}" alt="${esc(f.name)}">`:thumbnail(f)}<strong>${esc(f.name)}</strong><small>${f.size} · ${f.date}</small></div>`}openDialog('目标位置已有同名文件',`<p>“${esc(titleFor(path()))}”中已存在“${esc(incoming.name)}”。选择如何处理本次任务中的同名文件。</p><div class="conflict-files">${item(existing,'目标中的文件')}${item(incoming,'即将移入的文件')}</div><p class="scope-note">保留两份会自动编号。替换会覆盖目标中的同名文件。</p>`,cancelButton+'<button class="button" data-resolve="skip">跳过同名</button><button class="button danger" data-resolve="replace">替换</button><button class="button primary" data-resolve="keep">保留两份</button>')}
function nameDialog(rename=false){if(offlinePath())return notify('工作硬盘已断开，请重新连接后继续','external');const f=firstSelected();if(isArchive())return notify('压缩包为只读，请先解压','lock');if(rename&&!f)return;openDialog(rename?'重命名':'新建文件夹',`<label class="dialog-label" for="name-input">${rename?'文件名称':'文件夹名称'}</label><input class="dialog-input" id="name-input" value="${esc(rename?f.name:'未命名文件夹')}" autocomplete="off"><div id="name-error" class="dialog-error" role="alert"></div>`,cancelButton+`<button class="button primary" data-action="${rename?'confirm-rename':'confirm-new-folder'}">${rename?'保存名称':'创建文件夹'}</button>`);setTimeout(()=>{$('#name-input').focus();$('#name-input').select()},0)}
function saveName(rename){const value=$('#name-input').value.trim(),f=firstSelected();if(!value||/[/:]/.test(value)||value==='.'||value==='..')return $('#name-error').textContent='请输入有效名称，不要使用 / 或 :。';if(filesAt().some(x=>x.name===value&&(!rename||x.id!==f?.id)))return $('#name-error').textContent='此位置已有同名项目，请换一个名称。';state.undo=snapshot();if(rename){if(f.type==='folder'){const newTarget=path()+'/'+value;const replacements=Object.keys(dirs).filter(p=>p===f.target||p.startsWith(f.target+'/'));for(const old of replacements){dirs[newTarget+old.slice(f.target.length)]=dirs[old];delete dirs[old]}f.target=newTarget}f.name=value}else{const target=path()+'/'+value;dirs[target]=[];const entry=folder(uid(),value,target);dirs[path()].push(entry);state.selected=new Set([entry.id])}$('#dialog').close();render();notify(rename?'已更新示例文件名称':'已创建示例文件夹')}
function showPopover(content,anchor){popoverReturnFocus=rememberFocus(anchor instanceof HTMLElement?anchor:document.activeElement);const el=$('#popover'),window=$('.app-window'),wr=window.getBoundingClientRect(),r=(anchor||$('#more-button')).getBoundingClientRect();el.innerHTML=content;el.hidden=false;const width=el.offsetWidth,height=el.offsetHeight;el.style.left=Math.max(8,Math.min(wr.width-width-12,r.right-wr.left-width))+'px';el.style.top=Math.max(8,Math.min(wr.height-height-12,r.bottom-wr.top+7))+'px'}
function menuItem(label,action,symbol,shortcut='',disabled=false){return `<button class="menu-item ${action==='trash'?'danger':''}" data-action="${action}" ${disabled?'disabled':''}>${icon(symbol)}<span>${label}</span>${shortcut?`<kbd>${shortcut}</kbd>`:''}</button>`}
function moreMenu(anchor){const has=state.selected.size>0;showPopover(menuItem('快速预览','quick-look','eye','Space',!has)+menuItem('打开方式…','open-with','arrowUpRight','',!has)+'<div class="menu-rule"></div>'+menuItem('剪切','cut','scissors','⌘ X',!has||isArchive())+menuItem('复制','copy','copy','⌘ C',!has)+menuItem('粘贴','paste','clipboard','⌘ V',!state.clipboard||isArchive()||offlinePath())+menuItem('复制文件完整路径','copy-file-path','route','⌥⌘ C',!has)+menuItem('重命名…','rename','edit','Return',state.selected.size!==1||isArchive())+menuItem('新建文件夹…','new-folder','folderPlus','⇧⌘ N',isArchive()||offlinePath())+'<div class="menu-rule"></div>'+menuItem('移到废纸篓','trash','trash','⌘ ⌫',!has||isArchive())+'<div class="menu-rule"></div>'+menuItem('新建标签页','new-tab','plus','⌘ T'),anchor)}
function openWith(anchor){const f=firstSelected();if(!f)return;if(f.type==='folder')return openFile();const video=['video','unsupported'].includes(f.type),apps=f.type==='text'?[['文本编辑','document','系统文本编辑器',''],['Visual Studio Code','code','编辑文本与代码',''],['Xcode','code','开发工具','']]:f.type==='document'?[['预览','document','系统文稿查看器',''],['Adobe Acrobat','document','阅读与批注 PDF','color-orange']]:video?[['IINA','film','常用播放器',''],['VLC','play','兼容更多视频格式','color-orange'],['QuickTime Player','play','系统播放器','']]:[['预览','image','系统查看器',''],['Pixelmator Pro','edit','编辑图片','color-purple'],['Affinity Photo','image','编辑图片','color-orange']];apps.unshift(['内置预览',video?'play':f.type==='text'||f.type==='document'?'document':'image','在当前窗口快速查看','']);const current=state.defaults[ext(f)]||apps[0][0];showPopover(`<div class="menu-title">打开 ${esc(f.name)}</div>${apps.map(([name,sym,desc,color])=>`<button class="open-app-row" data-app="${esc(name)}"><span class="app-icon ${color}">${icon(sym)}</span><span><strong>${name}</strong><small>${desc}</small></span>${current===name?`<span class="check-icon">${icon('check')}</span>`:''}</button>`).join('')}<div class="menu-rule"></div><label class="remember-choice"><input id="remember-app" type="checkbox"><span>在 MyFolds 中始终使用此应用打开 ${ext(f).toUpperCase()} 文件</span></label><p class="menu-note">仅在本次演示内记住。系统默认应用保持独立。</p><div class="menu-rule"></div>${menuItem('更改系统默认应用…','system-default','settings')}`,anchor||($('[data-action="open-with"]')?.checkVisibility()?$('[data-action="open-with"]'):$('#more-button')))}
function systemDefault(){const f=firstSelected();openDialog('系统默认打开方式',`<p>本工具内默认仅影响从 MyFolds 打开的文件。要让 Finder 和其他系统入口也使用该应用，请在 macOS 中更改文件关联。</p><ol class="system-steps"><li>在 Finder 中选择 ${esc(f?.name||'一个文件')}，打开“显示简介”。</li><li>展开“打开方式”，选择应用。</li><li>点击“全部更改”，应用到同类文件。</li></ol><p class="scope-note">这是设计原型的说明，不会修改你的系统设置。</p>`,'<button class="button primary" data-action="close-dialog">知道了</button>')}
function openFile(){const f=firstSelected();if(!f)return;if(f.type==='folder'||f.type==='archive')return navigate(f.target);const preferred=state.defaults[ext(f)];if(preferred&&preferred!=='内置预览')return notify(`演示：使用${preferred}打开 ${f.name}`);if(preferred==='内置预览'||['image','video','unsupported','text'].includes(f.type))return quickLook(f);notify(`演示：使用预览打开 ${f.name}`)}
function quickLook(file=firstSelected()){if(!file)return;if(file.type==='folder'||file.type==='archive')return openFile();state.mediaId=file.id;state.zoom=false;renderMedia()}
function mediaFiles(){return filesAt().filter(f=>['image','video','unsupported','text','document'].includes(f.type))}
function renderMedia(){const list=mediaFiles(),f=list.find(x=>x.id===state.mediaId)||list[0];if(!f)return;state.mediaId=f.id;const d=$('#dialog'),focusedAction=d.open?document.activeElement?.dataset.action:null,focusedMedia=d.open?document.activeElement?.dataset.media:null;if(!d.open)dialogReturnFocus=rememberFocus();hidePopover();closePath();d.className='media-dialog';const media=f.type==='video'?`<video controls preload="metadata" poster="${f.image}" src="${f.video}" aria-label="${esc(f.name)}"></video>`:f.type==='image'?`<img class="${state.zoom?'zoomed':''}" src="${f.image}" alt="${esc(f.name)} 的示例图像">`:f.type==='text'?`<pre class="text-preview" style="width:70%;height:80%;background:#242421;color:#eeeee9;border:0">${esc(f.text)}</pre>`:`<div class="empty-state">${icon('film')}<h3>暂时无法预览此文件</h3><p>可以使用其他应用打开。</p><button class="button" data-action="media-open-with">选择打开应用</button></div>`;
 d.innerHTML=`<div class="media-top"><button class="icon-button" data-action="close-dialog" aria-label="关闭快速预览">${icon('close')}</button><div><h2 id="dialog-title">${esc(f.name)}</h2><small>${f.kind} · ${f.size}${f.dimensions?' · '+f.dimensions:''}</small></div><span class="media-top-spacer"></span><button class="icon-button" data-action="media-open-with" aria-label="选择打开应用" title="选择打开应用">${icon('arrowUpRight')}</button></div><div class="media-stage">${media}</div><div class="media-controls"><div class="media-nav"><button class="icon-button" data-action="media-prev" aria-label="上一个文件">${icon('chevronLeft')}</button><span>${list.indexOf(f)+1} / ${list.length}</span><button class="icon-button" data-action="media-next" aria-label="下一个文件">${icon('chevronRight')}</button></div><div class="media-filmstrip">${list.filter(x=>x.image).map(x=>`<button class="media-thumb ${x.id===f.id?'selected':''}" data-media="${x.id}" aria-label="查看 ${esc(x.name)}"><img src="${x.image}" alt=""></button>`).join('')}</div><div class="media-caption">${f.type==='image'?`<button class="button" data-action="media-zoom" aria-pressed="${state.zoom}">${state.zoom?'适合窗口':'100% 原图'}</button>`:'<span>左右方向键切换文件</span>'}</div></div>`;if(!d.open)d.showModal();else if(focusedAction)$(`[data-action="${focusedAction}"]`,d)?.focus({preventScroll:true});else if(focusedMedia)$(`[data-media="${focusedMedia}"]`,d)?.focus({preventScroll:true});
}
function cycleMedia(direction){const list=mediaFiles(),index=list.findIndex(f=>f.id===state.mediaId);state.mediaId=list[(index+direction+list.length)%list.length]?.id;state.zoom=false;renderMedia()}
function extractDialog(){if(!isArchive()){const f=firstSelected();if(f?.type==='archive'){navigate(f.target)}else return}const count=selectedFiles().length||filesAt().length;openDialog('解压到文件夹',`<p>将${selectedFiles().length?'所选':'当前目录下的'} ${count} 项提取到指定位置。压缩包本身保持不变。</p><label class="dialog-label" for="extract-path">目标路径</label><input class="dialog-input dialog-path" id="extract-path" value="${OUT}" spellcheck="false"><p class="scope-note">遇到同名文件时保留两份，自动为新文件编号。</p><div id="extract-error" class="dialog-error" role="alert"></div>`,cancelButton+'<button class="button primary" data-action="confirm-extract">开始解压</button>')}
function extract(){const target=$('#extract-path').value.trim().replace(/^~(?=\/|$)/,'/Users/demo');if(!(target in dirs)||isArchive(target))return $('#extract-error').textContent='请选择示例中的普通文件夹，例如 ~/Downloads。';const items=structuredClone(selectedFiles().length?selectedFiles():filesAt()),before=snapshot();$('#dialog').close();startTask(`正在解压 ${items.length} 项`,`旅行素材.7z → ${titleFor(target)}`,()=>{for(const f of items){const name=filesAt(target).some(x=>x.name===f.name)?uniqueName(f.name,target):f.name;dirs[target].push(copyEntry(f,target,name))}state.undo=before;return {title:`已解压 ${items.length} 项`,detail:`保存到 ${target} · 压缩包未修改`}})}
function trashDialog(){const files=selectedFiles();if(!files.length||isArchive())return;openDialog('移到废纸篓',`<p>将所选 ${files.length} 项移到废纸篓？你可以通过“撤销”恢复这次示例操作。</p>`,cancelButton+'<button class="button danger" data-action="confirm-trash">移到废纸篓</button>')}
function trash(){state.undo=snapshot();dirs['trash:'].push(...selectedFiles());dirs[path()]=filesAt().filter(f=>!state.selected.has(f.id));state.selected=new Set();$('#dialog').close();render();notify('已移到示例废纸篓，可按 ⌘Z 撤销')}
function settings(){openSettings()}
function help(){openDialog('把常用操作放回手边',`<p>这是使用示例数据的设计原型。可以切换下方场景，也可以直接操作文件列表。切换场景会重置示例文件与任务。</p><div class="shortcut-list"><span>编辑完整路径</span><kbd>⌘ L</kbd><span>搜索当前文件夹</span><kbd>⌘ F</kbd><span>新建 / 关闭标签页</span><kbd>⌘ T / ⌘ W</kbd><span>剪切 / 复制 / 粘贴</span><kbd>⌘ X / C / V</kbd><span>快速预览 / 关闭预览</span><kbd>Space / Esc</kbd><span>选择全部 / 多选</span><kbd>⌘ A / ⌘ 点击</kbd><span>重命名</span><kbd>Return</kbd><span>打开文件 / 上级目录</span><kbd>⌘ ↓ / ⌘ ↑</kbd><span>撤销示例文件操作</span><kbd>⌘ Z</kbd></div><p style="margin-top:18px">浏览器可能保留部分系统快捷键。工具栏和右键菜单提供相同操作入口。</p>`,'<button class="button primary" data-action="close-dialog">开始体验</button>')}
function statesDialog(){openDialog('查看边界状态',`<p>这些状态需要和日常浏览一样清楚：发生了什么、文件在哪里、下一步怎么恢复。</p><div class="state-buttons"><button class="button" data-state="empty">空文件夹</button><button class="button" data-state="no-results">无搜索结果</button><button class="button" data-state="denied">访问权限不足</button><button class="button" data-state="loading">正在加载</button><button class="button" data-state="disconnected">外接硬盘断开</button><button class="button" data-action="demo-conflict">同名文件冲突</button></div>`,'<button class="button" data-action="close-dialog">返回</button>')}
const scenes={browse:['你的文件，井然有序。','完整路径就在底部。空格预览，⌘X / ⌘C / ⌘V 整理文件。'],path:['路径，可以直接操作','点击地址栏或按 ⌘L。试试 ~/Downloads，或粘贴一个示例文件的完整路径。'],move:['移动之前，先把目标看清','两张照片已标记为剪切。当前目标是右侧“导出”，点击粘贴继续。'],media:['留在文件夹里，看完一组素材','切换图片与视频，查看原图或播放片段。按左右方向键连续浏览。'],open:['这次打开，还是以后都这样','选择应用，并明确它只影响这一次、此工具，还是整个系统。'],archive:['先看包里有什么，再决定解压','双击文件夹浏览压缩包内容。选中所需项目，指定解压目标。'],states:['遇到问题，也有清楚的下一步','查看空目录、权限、加载、同名冲突与设备断开的恢复方式。']};
function scene(name){clearInterval(taskTimer);clearTimeout(loadingTimer);$('#dialog').close();hidePopover();closePath();dirs=seedDirectories();state.undo=null;state.history=[];clearTimeout(toastTimer);$('#toast').hidden=true;state.scene=name;state.externalConnected=true;state.paths=[ROOT,OUT];state.active=0;state.selected=new Set();state.split=false;state.preview=false;state.query='';state.view='list';state.tabs=[{id:'tab-'+(++tabCounter),path:ROOT}];state.activeTab=state.tabs[0].id;state.task=null;state.clipboard=null;state.forcedState=null;$('#content-area').classList.remove('preview-mobile-open');$$('[data-scene]').forEach(el=>el.classList.toggle('active',el.dataset.scene===name));$('#scenario-title').textContent=scenes[name][0];$('#scenario-description').textContent=scenes[name][1];
 if(name==='media'||name==='open'){state.selected=new Set(['mountain']);state.view='grid';state.preview=true;if(matchMedia('(max-width:600px)').matches)$('#content-area').classList.add('preview-mobile-open')}
 if(name==='archive'){state.paths[0]=ARCH;state.selected=new Set()}
 if(name==='move'){state.view='list';state.selected=new Set(['mountain','coast']);clipboard('cut');state.split=true;state.active=1;state.selected=new Set()}
 render();if(name==='path')editPath();if(name==='media')quickLook();if(name==='open')openWith();if(name==='states')statesDialog();
}
function reset(){clearInterval(taskTimer);clearTimeout(loadingTimer);dirs=seedDirectories();state.history=[];state.undo=null;state.defaults={jpg:'内置预览',heic:'内置预览',mp4:'内置预览'};scene('browse');notify('示例文件与操作已重置')}
function sortMenu(anchor){showPopover(`<div class="menu-title">排序方式</div>${['name','date','type','size'].map((key,i)=>`<button class="menu-item" data-sort="${key}">${icon(state.sort===key?'check':'sort')}<span>${['名称','修改日期','类型','大小'][i]}</span></button>`).join('')}<div class="menu-rule"></div><button class="menu-item" data-action="reverse-sort">${icon('sort')}<span>${state.ascending?'改为降序':'改为升序'}</span></button>`,anchor)}
const actions={
 'edit-path':()=>editPath(),'copy-path':()=>copyPath(shownPath(path())),'copy-file-path':()=>{const f=firstSelected();if(f)copyPath(shownPath(path())+'/'+f.name)},
 back:()=>{const last=state.history.pop();if(last)navigate(last.path,{pane:last.pane,record:false})},up:()=>navigate(parentPath(path())),
 cut:()=>clipboard('cut'),copy:()=>clipboard('copy'),paste:()=>paste(),'cancel-clipboard':()=>{state.clipboard=null;render();focusFile(firstSelected()?.id)},
 'new-folder':()=>nameDialog(),rename:()=>nameDialog(true),'confirm-new-folder':()=>saveName(false),'confirm-rename':()=>saveName(true),
 more:el=>moreMenu(el),list:()=>{state.view='list';render()},grid:()=>{state.view='grid';render()},
 split:()=>{state.split=!state.split;if(!state.split){state.active=0;state.selected=new Set()}render()},
 'sidebar-toggle':()=>{$('.app-window').classList.toggle(matchMedia('(max-width:800px)').matches?'sidebar-open':'sidebar-hidden')},
 'preview-toggle':()=>{state.preview=!state.preview;state.split=false;state.active=0;render()},
 'open-file':()=>openFile(),'quick-look':()=>quickLook(),'open-with':el=>openWith(el),'system-default':()=>systemDefault(),
 'media-next':()=>cycleMedia(1),'media-prev':()=>cycleMedia(-1),'media-zoom':()=>{state.zoom=!state.zoom;renderMedia()},'media-open-with':()=>{const id=state.mediaId;$('#dialog').close();state.selected=new Set([id]);render();openWith()},
 'close-dialog':()=>$('#dialog').close(),extract:()=>extractDialog(),'confirm-extract':()=>extract(),
 trash:()=>trashDialog(),'confirm-trash':()=>trash(),'trash-view':()=>navigate('trash:'),
 theme:()=>setTheme(document.body.dataset.theme==='dark'?'light':'dark'),transparency:()=>setTransparency(document.body.dataset.transparency!=='reduced'),settings:()=>settings(),help:()=>help(),reset:()=>reset(),
 'cancel-task':()=>cancelTask(),'dismiss-task':()=>{state.task=null;renderTask();focusFile(firstSelected()?.id)},
 undo:()=>{if(!state.undo)return notify('目前没有可以撤销的操作','help');dirs=state.undo.dirs;state.paths=state.undo.paths;state.undo=null;state.task=null;state.selected=new Set();state.clipboard=null;render();notify('已撤销上一次示例文件操作')},
 tasks:()=>{if(state.task){$('#task-shelf').hidden=false;notify(state.task.running?'任务正在进行，可在底部取消':'最近任务已显示在底部')}else openDialog('文件任务','<p>目前没有进行中的任务。复制、移动或解压时，会在这里显示进度和结果。</p>','<button class="button primary" data-action="close-dialog">知道了</button>')},
 sort:el=>sortMenu(el),'reverse-sort':()=>{state.ascending=!state.ascending;hidePopover();render()},
 'clear-search':()=>{state.query='';render()},authorize:()=>{state.forcedState=null;if(path()==='/Volumes/工作硬盘')dirs[path()]=[folder('external-backup','备份','/Volumes/工作硬盘/备份')];dirs['/Volumes/工作硬盘/备份']=[];if(path()==='/Volumes/工作硬盘'){state.paths[state.active]='/Volumes/工作硬盘/备份'}render();notify('已演示授权后的恢复流程；没有请求系统权限')},
 'cancel-loading':()=>{clearTimeout(loadingTimer);state.forcedState=null;render()},reconnect:()=>{state.forcedState=null;state.externalConnected=true;dirs['/Volumes/工作硬盘']||=[folder('external-backup','备份','/Volumes/工作硬盘/备份')];dirs['/Volumes/工作硬盘/备份']||=[];render();notify('工作硬盘已重新连接')},
 'demo-conflict':()=>{scene('move');paste()},'new-tab':()=>addTab()
};
const systemAppearance=matchMedia('(prefers-color-scheme:dark)');
let appearanceMode='system';
function setTheme(mode){appearanceMode=mode;const theme=mode==='system'?(systemAppearance.matches?'dark':'light'):mode;document.body.dataset.theme=theme;$('#theme-button').innerHTML=icon(theme==='dark'?'sun':'moon');$('#theme-button').setAttribute('aria-label',theme==='dark'?'切换浅色外观':'切换深色外观');$('#theme-button').title=theme==='dark'?'切换浅色外观':'切换深色外观';document.dispatchEvent(new Event('myfolds-appearance-change'))}
systemAppearance.addEventListener('change',()=>{if(appearanceMode==='system')setTheme('system')});
function setTransparency(reduced){document.body.dataset.transparency=reduced?'reduced':'regular';const button=$('#transparency-button');button.setAttribute('aria-pressed',String(reduced));button.title=reduced?'恢复玻璃效果':'减少透明度';button.setAttribute('aria-label',button.title);document.dispatchEvent(new Event('myfolds-appearance-change'))}
async function copyPath(value){hidePopover();try{await navigator.clipboard.writeText(value);notify('已复制路径：'+value)}catch{openDialog('复制完整路径',`<p>浏览器未授予剪贴板权限，可以手动复制下方路径。</p><input class="dialog-input dialog-path" id="manual-copy" value="${esc(value)}" readonly>`,'<button class="button primary" data-action="close-dialog">完成</button>');$('#manual-copy').select()}}
document.addEventListener('click',event=>{
 const el=event.target;
 const action=el.closest('[data-action]');if(action){if(!action.disabled){const key=action.dataset.action;if(!['open-with','more','sort'].includes(key))hidePopover();actions[key]?.(action)}return}
 const tabClose=el.closest('[data-close-tab]');if(tabClose)return closeTab(tabClose.dataset.closeTab);
 const tab=el.closest('[data-tab]');if(tab)return activateTab(tab.dataset.tab);
 const sceneButton=el.closest('[data-scene]');if(sceneButton)return scene(sceneButton.dataset.scene);
 const folderButton=el.closest('[data-folder]');if(folderButton)return navigate(folderButton.dataset.folder);
 const goto=el.closest('[data-goto]');if(goto)return navigate(goto.dataset.goto);
 const resolve=el.closest('[data-resolve]');if(resolve){$('#dialog').close();paste(resolve.dataset.resolve);return}
 const sort=el.closest('[data-sort]');if(sort){state.sort=sort.dataset.sort;hidePopover();render();return}
 const app=el.closest('[data-app]');if(app){const f=firstSelected(),remember=$('#remember-app')?.checked;if(f&&remember)state.defaults[ext(f)]=app.dataset.app;hidePopover();if(app.dataset.app==='内置预览'){quickLook(f);return}notify(`演示：用${app.dataset.app}打开${f?' '+f.name:''}${remember?'，并在 MyFolds 中记住选择':''}`);return}
 const media=el.closest('[data-media]');if(media){state.mediaId=media.dataset.media;state.zoom=false;renderMedia();return}
 const forced=el.closest('[data-state]');if(forced){$('#dialog').close();state.forcedState=forced.dataset.state;state.selected=new Set();if(state.forcedState==='no-results'){state.forcedState=null;state.query='不存在的素材'}if(state.forcedState==='empty')state.paths[0]='/Users/demo/Desktop';if(state.forcedState==='disconnected'){state.externalConnected=false;state.paths[state.active]='/Volumes/工作硬盘'}render();if(state.forcedState==='loading')loadingTimer=setTimeout(()=>{state.forcedState=null;render()},4000);return}
 const row=el.closest('[data-id]');if(row){const now=performance.now(),double=lastRowClick.id===row.dataset.id&&now-lastRowClick.time<420&&!event.metaKey&&!event.ctrlKey&&!event.shiftKey;lastRowClick={id:row.dataset.id,time:now};selectFile(row.dataset.id,Number(row.dataset.pane),event);if(double){lastRowClick={id:null,time:0};openFile()}return}
 const pane=el.closest('.file-pane');if(pane&&!el.closest('button,input,a')){state.active=Number(pane.dataset.pane);state.selected=new Set();lastRowClick={id:null,time:0};render();pane.focus({preventScroll:true})}
 if(!el.closest('#popover'))hidePopover();if(!el.closest('.address-wrap'))closePath();
});

document.addEventListener('contextmenu',event=>{
 const row=event.target.closest('[data-id]'),pane=event.target.closest('.file-pane');if(!pane)return;
 event.preventDefault();hidePopover();closePath();
 if(row){if(state.active!==Number(row.dataset.pane)||!state.selected.has(row.dataset.id))selectFile(row.dataset.id,Number(row.dataset.pane));else focusFile(row.dataset.id,Number(row.dataset.pane))}
 else{state.active=Number(pane.dataset.pane);state.selected=new Set();render();pane.focus({preventScroll:true})}
 moreMenu({getBoundingClientRect:()=>({right:event.clientX+230,bottom:event.clientY})});
});
$('#search-input').addEventListener('input',event=>{state.query=event.target.value;state.selected=new Set();render()});
$('#path-input').addEventListener('input',event=>showSuggestions(event.target.value));
$('#address-form').addEventListener('submit',event=>{event.preventDefault();navigate($('#path-input').value)});
$('#dialog').addEventListener('close',()=>{
 $$('video',$('#dialog')).forEach(video=>video.pause());
 if(!$('#dialog').open&&$('#popover').hidden)restoreFocus(dialogReturnFocus);
});
window.addEventListener('blur',()=>$('.app-window').classList.add('window-inactive'));
window.addEventListener('focus',()=>$('.app-window').classList.remove('window-inactive'));
document.addEventListener('keydown',event=>{
 const key=event.key.toLowerCase(),cmd=event.metaKey||event.ctrlKey,focused=document.activeElement;
 const input=focused?.matches('input,textarea,select,[contenteditable=true]'),control=focused?.closest('button,a,input,textarea,select,video,[contenteditable=true]'),dialog=$('#dialog');
 if(dialog.open){
  if(dialog.classList.contains('media-dialog')&&focused?.tagName!=='VIDEO'){
   if(event.key==='ArrowRight'||event.key==='ArrowLeft'){event.preventDefault();cycleMedia(event.key==='ArrowRight'?1:-1)}
   if(event.key===' '&&!control){event.preventDefault();dialog.close()}
  }
  if(event.key==='Enter'&&focused?.id==='name-input'){event.preventDefault();saveName($('#dialog [data-action="confirm-rename"]')!==null)}
  return;
 }
 if(cmd&&key===','){event.preventDefault();settings();return}
 if(event.key==='Escape'){
  if(!$('#popover').hidden){event.preventDefault();hidePopover(true);return}
  if(!$('#address-form').hidden){event.preventDefault();closePath(true);return}
  if(state.query){event.preventDefault();state.query='';render();return}
  if(state.selected.size){event.preventDefault();state.selected=new Set();render()}
  return;
 }
 if(cmd&&key==='t'){event.preventDefault();addTab();return}
 if(cmd&&key==='w'&&state.tabs.length>1){event.preventDefault();closeTab(state.activeTab);return}
 if(focused?.matches('[role=tab]')&&['ArrowLeft','ArrowRight'].includes(event.key)){event.preventDefault();const index=state.tabs.findIndex(t=>t.id===state.activeTab),step=event.key==='ArrowRight'?1:-1;activateTab(state.tabs[(index+step+state.tabs.length)%state.tabs.length].id);return}
 if(cmd&&key==='l'){event.preventDefault();hidePopover();editPath();return}
 if(cmd&&key==='f'){event.preventDefault();hidePopover();$('#search-input').focus();return}
 if(!$('#popover').hidden){
  if(['ArrowDown','ArrowUp','Home','End'].includes(event.key)){
   event.preventDefault();const options=$$('button:not(:disabled),input:not(:disabled)',$('#popover')),index=options.indexOf(focused);
   const next=event.key==='Home'?0:event.key==='End'?options.length-1:event.key==='ArrowDown'?(index+1)%options.length:(index-1+options.length)%options.length;
   options[next]?.focus();
  }
  return;
 }
 if(input)return;
 if(cmd&&['x','c','v'].includes(key)){event.preventDefault();if(event.altKey&&key==='c')actions['copy-file-path']();else actions[{x:'cut',c:'copy',v:'paste'}[key]]();return}
 if(cmd&&key==='a'){event.preventDefault();state.selected=new Set(visibleFiles(path()).map(f=>f.id));render();return}
 if(cmd&&key==='z'){event.preventDefault();actions.undo();return}
 if(cmd&&event.shiftKey&&key==='n'){event.preventDefault();nameDialog();return}
 if(cmd&&event.key==='ArrowUp'){event.preventDefault();actions.up();return}
 if(cmd&&event.key==='ArrowDown'){event.preventDefault();openFile();return}
 if(cmd&&event.key==='Backspace'){event.preventDefault();trashDialog();return}
 // Native control activation takes precedence over file shortcuts.
 if(control)return;
 if(event.key===' '){event.preventDefault();quickLook();return}
 if(event.key==='Enter'){event.preventDefault();nameDialog(true);return}
 if(['ArrowDown','ArrowUp','ArrowLeft','ArrowRight'].includes(event.key)){
  if(state.view==='list'&&['ArrowLeft','ArrowRight'].includes(event.key))return;
  const list=visibleFiles(path()),container=$(state.active?'#target-pane':'#main-pane'),grid=$('.grid-files',container);
  if(!list.length)return;
  event.preventDefault();const columns=grid?getComputedStyle(grid).gridTemplateColumns.split(' ').length:1;
  const focusedId=focused?.dataset.id,index=list.findIndex(f=>f.id===focusedId||(focusedId===undefined&&state.selected.has(f.id)));
  const step={ArrowDown:columns,ArrowUp:-columns,ArrowLeft:-1,ArrowRight:1}[event.key];
  const next=list[index<0?0:Math.max(0,Math.min(list.length-1,index+step))];
  selectFile(next.id,state.active,event.shiftKey?{shiftKey:true}:{});focusFile(next.id,state.active,true);
 }
});
// Clip scrolling rows below the header, so both share one translucent material.
function syncListHeader(scroller){
 if(scroller.querySelector('.file-table')) scroller.style.setProperty('--list-scroll-offset',Math.max(0,scroller.scrollTop)+'px');
}
document.addEventListener('scroll', event => {
 const scroller=event.target;
 if(scroller instanceof Element && scroller.matches('.files-scroll')) syncListHeader(scroller);
}, {capture:true,passive:true});
paintIcons();setTheme('system');setTransparency(matchMedia('(prefers-reduced-transparency:reduce)').matches);render();
