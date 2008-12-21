<map version="0.9.0">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1229864059187" ID="ID_387462060" MODIFIED="1229864080562" TEXT="MDA">
<node CREATED="1229864152625" ID="ID_1624458846" MODIFIED="1229864172796" POSITION="right" TEXT="Technical">
<node CREATED="1229864189890" ID="ID_1503375173" MODIFIED="1229864192671" TEXT="Perl">
<node CREATED="1229864194921" ID="ID_715059909" MODIFIED="1229867765406" TEXT="Tk">
<node CREATED="1229864200515" ID="ID_1712973427" MODIFIED="1229865169328" TEXT="Widgets">
<node CREATED="1229864289546" ID="ID_267672594" MODIFIED="1229865239875" TEXT="ttk">
<node CREATED="1229864216078" ID="ID_385331283" MODIFIED="1229868059203" TEXT="ttk::notebook">
<node CREATED="1229864321468" FOLDED="true" ID="ID_1315135432" MODIFIED="1229868060343" TEXT="Style commands">
<node CREATED="1229864512593" ID="ID_777643480" MODIFIED="1229865122671" TEXT="Notebook Layout">
<node CREATED="1229864327515" ID="ID_20897898" MODIFIED="1229864490484">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Perl Tkx::i::call('style', 'layout', 'TNotebook')
    </p>
    <p>
      Tk: style layout TNotebook
    </p>
    <p>
      
    </p>
    <p>
      TNotebook layout options:
    </p>
    <p>
      $VAR1 = 'Notebook.client';
    </p>
    <p>
      $VAR2 = '-sticky';
    </p>
    <p>
      $VAR3 = 'nswe';
    </p>
  </body>
</html></richcontent>
</node>
<node CREATED="1229864541609" ID="ID_1466725019" MODIFIED="1229864745421">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Perl: Tkx::i::call('style', 'layout', 'TNotebook.Tab')
    </p>
    <p>
      Tk: style layout TNotebook.Tab
    </p>
    <p>
      
    </p>
    <pre>TNotebook.Tab layout options: 
$VAR1 = 'Notebook.tab';
$VAR2 = '-sticky';
$VAR3 = 'nswe';
$VAR4 = '-children';
$VAR5 = bless( [
                 'Notebook.padding',
                 '-side',
                 'top',
                 '-sticky',
                 'nswe',
                 '-children',
                 bless( [
                          'Notebook.focus',
                          '-side',
                          'top',
                          '-sticky',
                          'nswe',
                          '-children',
                          bless( [
                                   'Notebook.label',
                                   '-side',
                                   'top',
                                   '-sticky',
                                   ''
                                 ], 'Tcl::List' )
                        ], 'Tcl::List' )
               ], 'Tcl::List' );</pre>
    <p>
      
    </p>
  </body>
</html>
</richcontent>
</node>
</node>
<node CREATED="1229864763843" ID="ID_209939622" MODIFIED="1229865140843" TEXT="Element options">
<node CREATED="1229864768968" ID="ID_30788830" MODIFIED="1229864823203">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Perl: Tkx::i::call('style', 'element', 'options', 'Notebook.tab')
    </p>
    <p>
      Tk: style element options Notebook.tab
    </p>
    <p>
      
    </p>
    <p>
      notebook.tab element options:
    </p>
    <p>
      $VAR1 = '-borderwidth';
    </p>
    <p>
      $VAR2 = '-background';
    </p>
  </body>
</html>
</richcontent>
</node>
<node CREATED="1229864852468" ID="ID_1659580893" MODIFIED="1229864881921">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Perl: Tkx::i::call('style', 'element', 'options', 'Notebook.label')
    </p>
    <p>
      Tk: style element options Notebook.label
    </p>
    <p>
      
    </p>
    <p>
      notebook.label element options:
    </p>
    <p>
      $VAR1 = '-compound';
    </p>
    <p>
      $VAR2 = '-space';
    </p>
    <p>
      $VAR3 = '-text';
    </p>
    <p>
      $VAR4 = '-font';
    </p>
    <p>
      $VAR5 = '-foreground';
    </p>
    <p>
      $VAR6 = '-underline';
    </p>
    <p>
      $VAR7 = '-width';
    </p>
    <p>
      $VAR8 = '-anchor';
    </p>
    <p>
      $VAR9 = '-justify';
    </p>
    <p>
      $VAR10 = '-wraplength';
    </p>
    <p>
      $VAR11 = '-embossed';
    </p>
    <p>
      $VAR12 = '-image';
    </p>
    <p>
      $VAR13 = '-stipple';
    </p>
    <p>
      $VAR14 = '-background';
    </p>
  </body>
</html>
</richcontent>
</node>
<node CREATED="1229864895546" ID="ID_1726309900" MODIFIED="1229864920203">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Perl Tkx::i::call('style', 'element', 'options', 'Notebook.padding')
    </p>
    <p>
      Tk: style element options Notebook.padding
    </p>
    <p>
      
    </p>
    <p>
      notebook.padding element options:
    </p>
    <p>
      $VAR1 = '-padding';
    </p>
    <p>
      $VAR2 = '-relief';
    </p>
    <p>
      $VAR3 = '-shiftrelief';
    </p>
  </body>
</html>
</richcontent>
</node>
</node>
</node>
<node CREATED="1229868064062" FOLDED="true" ID="ID_168190730" MODIFIED="1229868140328" TEXT="Ins&#xe9;rer un onglet avec une image">
<node CREATED="1229868070984" ID="ID_7919855" MODIFIED="1229868138859" TEXT="Tkx::image(&quot;create&quot;, &quot;photo&quot;, -file =&gt; &apos;graphics/music.png&apos;);&#xa;$theNotebook-&gt;m_tab(0, -image =&gt; $picto, -compound =&gt; &apos;left&apos;, -text =&gt; &apos;TUTU&apos;))"/>
</node>
</node>
<node CREATED="1229864967328" FOLDED="true" ID="ID_914658836" MODIFIED="1229867978796" TEXT="Global Style commands">
<node CREATED="1229864982750" ID="ID_563787783" MODIFIED="1229865046875">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Create Specific Styles (Frame and Label):
    </p>
    <p>
      
    </p>
    <p>
      Tkx::ttk__style('configure', 'Blue.TFrame', -background =&gt; 'blue', -foreground =&gt; 'black', -relief =&gt; 'solid');
    </p>
    <p>
      Tkx::ttk__style('configure', 'Blue.TLabel', -background =&gt; 'blue', -foreground =&gt; 'yellow', -relief =&gt; 'flat');
    </p>
  </body>
</html>
</richcontent>
</node>
<node CREATED="1229865049937" ID="ID_1885852442" MODIFIED="1229865107796">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      Use style at widget creation:
    </p>
    <p>
      
    </p>
    <p>
      $self-&gt;{blankTabWidget} = $self-&gt;widget()-&gt;new_ttk__frame(-name =&gt; 'noMetaData', -style =&gt; 'Blue.TFrame');
    </p>
    <p>
      $self-&gt;{blankTab}{labelW} = $self-&gt;{blankTabWidget}-&gt;new_ttk__label( -text =&gt; 'No metadata found in this folder.', -style =&gt; 'Blue.TLabel');
    </p>
  </body>
</html>
</richcontent>
</node>
</node>
</node>
<node CREATED="1229865170578" ID="ID_166125071" MODIFIED="1229865176640" TEXT="Geometry Manager">
<node CREATED="1229865178578" ID="ID_1497621712" MODIFIED="1229865182921" TEXT="Pack">
<node CREATED="1229865186281" ID="ID_1853367991" MODIFIED="1229865222531">
<richcontent TYPE="NODE"><html>
  <head>
    
  </head>
  <body>
    <p>
      $self-&gt;{blankTab}{labelW}-&gt;g_pack(-anchor =&gt; 'center', -expand =&gt; 'true', -padx =&gt; 5);
    </p>
    <p>
      $self-&gt;{blankTabWidget}-&gt;g_pack(-fill =&gt; &quot;both&quot;, -expand =&gt; &quot;yes&quot;);
    </p>
    <p>
      $self-&gt;widget()-&gt;g_pack(-fill =&gt; &quot;both&quot;, -expand =&gt; &quot;yes&quot;);
    </p>
  </body>
</html>
</richcontent>
</node>
</node>
<node CREATED="1229865183953" ID="ID_786217872" MODIFIED="1229868483171" TEXT="Grid">
<node CREATED="1229868214937" ID="ID_1914197763" MODIFIED="1229868319281" TEXT="Configurer le grid pour show/hide ">
<node CREATED="1229868220250" ID="ID_1928476632" MODIFIED="1229868307796" TEXT="Tkx::grid(&quot;columnconfigure&quot;, $theFrameWidget, 0, -weight =&gt; 1);&#xa;Tkx::grid(&quot;rowconfigure&quot;, $theFrameWidget, 1, -weight =&gt; 1);"/>
</node>
<node CREATED="1229868321515" ID="ID_1709554801" MODIFIED="1229868389281" TEXT="Ajouter des &#xe9;l&#xe9;ments dans le grid">
<node CREATED="1229868325031" ID="ID_1991150229" MODIFIED="1229868380484" TEXT="$self-&gt;{radioButtonFrameW}-&gt;g_grid(-row=&gt;0, -column=&gt;0,  -sticky =&gt; &apos;nesw&apos;);&#xa;$self-&gt;{retrievedFrameW}-&gt;g_grid(-columnspan =&gt; 2, -row=&gt;1, -column=&gt;0,  -sticky =&gt; &apos;nesw&apos;);"/>
</node>
<node CREATED="1229868486078" ID="ID_1295370519" MODIFIED="1229868497406" TEXT="Show a frame pour show/hide">
<node CREATED="1229868499781" ID="ID_1093929091" MODIFIED="1229868542843" TEXT="&#xa;Tkx::grid(&apos;remove&apos;, $self-&gt;subFrame($subFrameName));&#xa;&#xa;$self-&gt;subFrame($frameToShowName)-&gt;g_grid(-columnspan =&gt; 2, -row=&gt;1, -column=&gt;0,  -sticky =&gt; &apos;nesw&apos;);"/>
</node>
</node>
</node>
</node>
<node CREATED="1229867767171" ID="ID_247330940" MODIFIED="1229867770062" TEXT="Images">
<node CREATED="1229867770656" ID="ID_308711843" MODIFIED="1229867982031" TEXT="Cr&#xe9;er une image">
<node CREATED="1229867777843" ID="ID_510630786" MODIFIED="1229867794906" TEXT="my $picto = Tkx::image(&quot;create&quot;, &quot;photo&quot;, -file =&gt; &apos;graphics/music.png&apos;);"/>
</node>
<node CREATED="1229867830156" ID="ID_1271526724" MODIFIED="1229867980921" TEXT="D&#xe9;clarer la lib png">
<node CREATED="1229867835390" ID="ID_875930350" MODIFIED="1229867845421" TEXT="Tkx::package(&quot;require&quot;, &quot;img::png&quot;);"/>
</node>
</node>
<node CREATED="1229868010015" ID="ID_97833897" MODIFIED="1229868011640" TEXT="Divers">
<node CREATED="1229868012218" ID="ID_648769963" MODIFIED="1229868018968" TEXT="Activer le mode debug">
<node CREATED="1229868019953" ID="ID_1746399078" MODIFIED="1229868021250" TEXT="$Tkx::TRACE=&apos;false&apos;;"/>
</node>
</node>
</node>
</node>
</node>
<node CREATED="1229864176562" ID="ID_1441725541" MODIFIED="1229864182046" POSITION="left" TEXT="Functionnal"/>
</node>
</map>
