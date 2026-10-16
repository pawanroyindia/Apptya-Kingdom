import math, os, random, struct, wave
OUT=os.path.abspath("GodotProject/assets/production/audio")
os.makedirs(OUT,exist_ok=True)
SR=22050
random.seed(918)
def env(t,d,a=0.02,r=0.3):
    return min(1,t/max(a,1e-4))*max(0,min(1,(d-t)/max(r,1e-4)))
def write_wav(name, samples):
    path=os.path.join(OUT,name)
    with wave.open(path,"wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        b=bytearray()
        for l,r in samples:
            b.extend(struct.pack("<hh",int(max(-1,min(1,l))*32767),int(max(-1,min(1,r))*32767)))
        w.writeframes(b)
def music():
    dur=36.0; total=int(SR*dur); out=[]
    # Original modal fantasy theme: strings, bell-like plucks, bass, frame drum and layered harmony.
    chords=[(110.0,164.81,220.0),(98.0,146.83,196.0),(130.81,164.81,196.0),(87.31,130.81,174.61),
            (110.0,164.81,220.0),(130.81,196.0,261.63),(98.0,146.83,196.0),(82.41,123.47,164.81)]
    melody=[440,392,329.63,293.66,329.63,392,440,523.25,493.88,440,392,329.63,293.66,329.63,392,440]
    for i in range(total):
        t=i/SR; bar=int(t/4.5)%len(chords); local=t%4.5
        l=r=0.0
        for j,f in enumerate(chords[bar]):
            phase=2*math.pi*f*t
            # Warm sustained bowed tone with slow vibrato and upper harmonics.
            tone=(math.sin(phase+0.12*math.sin(2*math.pi*4.3*t))+
                  0.38*math.sin(2*phase)+0.13*math.sin(3*phase))
            pad=tone*(0.042 if j else 0.055)*(0.82+0.18*math.sin(2*math.pi*0.11*t))
            l+=pad*(0.8 if j==1 else 1.0); r+=pad*(0.8 if j==0 else 1.0)
        # Arpeggiated plucked strings, stereo alternation and natural decay.
        step=int(t/0.375); beat=t%0.375
        f=chords[bar][(step+bar)%3]*2
        pluck=(math.sin(2*math.pi*f*beat)+0.42*math.sin(2*math.pi*f*2.01*beat))*math.exp(-beat*8.5)*0.095
        if step%2: l+=pluck; r+=pluck*0.55
        else: r+=pluck; l+=pluck*0.55
        # Lead phrase every half bar, with a soft bell attack and decaying partials.
        mstep=int(local/0.5625); mt=local%0.5625
        mf=melody[(bar*2+mstep)%len(melody)]
        bell=(math.sin(2*math.pi*mf*mt)+0.35*math.sin(2*math.pi*mf*2.76*mt)+0.14*math.sin(2*math.pi*mf*4.1*mt))*math.exp(-mt*4.2)*0.052
        if mstep%2: r+=bell; l+=bell*0.68
        else: l+=bell; r+=bell*0.68
        # Low cinematic pulse and quiet frame-drum transients on the beat.
        beatpos=t%1.125
        kick=math.sin(2*math.pi*(72-28*min(1,beatpos*5))*beatpos)*math.exp(-beatpos*11)*0.075
        if beatpos<0.25: l+=kick; r+=kick
        # Soft cymbal/shaker texture only at phrase accents.
        phrase=t%4.5
        if phrase<0.045:
            n=(random.random()*2-1)*math.exp(-phrase*70)*0.022
            l+=n; r-=n*0.7
        # Smooth fade-in/out and conservative peak level.
        fade=min(1,t/1.4,(dur-t)/1.2)
        out.append((math.tanh(l*1.8)*fade,math.tanh(r*1.8)*fade))
    write_wav("kingdom_theme.wav",out)
def effect(name,kind):
    d={"gather":0.62,"build":0.9,"train":1.05,"victory":1.8,"defeat":1.6,"scout":0.75}[kind]
    samples=[]
    seq={"gather":[880,1320],"build":[220,330,440],"train":[196,293.66,392],"victory":[392,493.88,587.33,783.99],"defeat":[392,311.13,233.08],"scout":[523.25,659.25]}[kind]
    for i in range(int(SR*d)):
        t=i/SR; s=0.0
        for j,f in enumerate(seq):
            start=j*(d/(len(seq)+0.25)); u=t-start
            if u>=0:
                e=min(1,u/0.008)*math.exp(-u*(4.0 if kind in ("victory","defeat") else 8.5))
                vibr=1+0.004*math.sin(2*math.pi*5*t)
                s+=(math.sin(2*math.pi*f*vibr*u)+0.23*math.sin(2*math.pi*f*2.01*u))*e*0.18
        noise=(random.random()*2-1)*math.exp(-t*30)*0.06 if kind in ("build","gather") else 0
        s+=noise
        v=math.tanh(s*1.7)
        samples.append((v,v*0.94))
    write_wav(name+".wav",samples)
music()
for k in ("gather","build","train","victory","defeat","scout"): effect(k,k)
print("APPTYA_ASSET_PIPELINE_AUDIO_SUCCESS")
