import hashlib,json,zipfile
from pathlib import Path
r=Path(r'C:/SourceCodes/WoolGame')
p=r/'Builds/Rebuild/WoolRescue.pck'
with zipfile.ZipFile(r/'Builds/Rebuild/WoolRescue-Android.apk') as a,zipfile.ZipFile(r/'Builds/Rebuild/WoolRescue-Windows.zip') as w:
 assert a.read('assets/game.pck')==p.read_bytes()==w.read('WoolRescue/WoolRescue.pck')
 assert w.read('WoolRescue/WoolRescue.exe')==(r/'Builds/Rebuild/WoolRescue.exe').read_bytes()
 report={'same_pck_in_windows_zip_and_android':True,'same_windows_exe_in_zip':True,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
 (r/'Evidence/Rebuild/FunRevision/package-integrity.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print(json.dumps(report))
