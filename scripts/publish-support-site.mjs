#!/usr/bin/env node
// Publishes only site/, never the repository or local Studio.
import {execFileSync} from 'node:child_process';
import {readdir,readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const repository='mim-Armand/8bit-stickers';
const base=`repos/${repository}`;
const apply=process.argv.includes('--apply');
function github(method,endpoint,body,allow404=false){
  try{return JSON.parse(execFileSync('gh',['api',endpoint,'--method',method,...(body?['--input','-']:[])],{input:body?JSON.stringify(body):undefined,encoding:'utf8',stdio:['pipe','pipe','pipe']}));}
  catch(error){let response;try{response=JSON.parse(error.stdout);}catch{}if(allow404&&response?.status==='404')return null;if(allow404&&response?.status===404)return null;throw new Error(`GitHub ${method} ${endpoint}: ${error.stderr?.toString().trim()||error.message}`);}
}
async function walk(directory,prefix=''){
  const files=[];
  for(const item of await readdir(directory,{withFileTypes:true})){
    const relative=path.posix.join(prefix,item.name);
    if(item.isDirectory())files.push(...await walk(path.join(directory,item.name),relative));
    else if(item.isFile())files.push(relative);
    else throw new Error(`Unexpected site entry: ${relative}`);
  }
  return files.sort();
}
const files=await walk(path.join(root,'site'));
if(files.some(f=>f!=='\.nojekyll'&&!/\.(html|css|svg|png)$/.test(f)))throw new Error('Unexpected public site file type');
console.log(JSON.stringify({repository,source:'site/',files,url:'https://mim-armand.github.io/8bit-stickers/',apply},null,2));
if(apply){
  const head=github('GET',`${base}/git/ref/heads/gh-pages`,undefined,true);
  const existing=github('GET',`${base}/pages`,undefined,true);
  if(existing&&(existing.source?.branch!=='gh-pages'||existing.source?.path!=='/'))throw new Error('Existing Pages source differs; refusing to replace it.');
  const tree=[];
  for(const filename of files){
    const blob=github('POST',`${base}/git/blobs`,{encoding:'base64',content:(await readFile(path.join(root,'site',filename))).toString('base64')});
    tree.push({path:filename,mode:'100644',type:'blob',sha:blob.sha});
  }
  const savedTree=github('POST',`${base}/git/trees`,{tree});
  const commit=github('POST',`${base}/git/commits`,{message:'Publish 8 bit art support and privacy pages',tree:savedTree.sha,parents:head?[head.object.sha]:[]});
  if(head)github('PATCH',`${base}/git/refs/heads/gh-pages`,{sha:commit.sha,force:false});
  else github('POST',`${base}/git/refs`,{ref:'refs/heads/gh-pages',sha:commit.sha});
  const pages=existing||github('POST',`${base}/pages`,{source:{branch:'gh-pages',path:'/'},build_type:'legacy'});
  console.log(JSON.stringify({commit:commit.sha,url:pages.html_url,status:pages.status,source:pages.source},null,2));
}
