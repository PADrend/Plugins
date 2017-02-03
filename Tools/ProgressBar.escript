
var ProgressBar = new Type;

ProgressBar.usePercentage @(private) := false;
ProgressBar.computeETR @(private) := false;
ProgressBar.consoleOutput @(private) := false;
ProgressBar.clearScreen @(private) := false;
ProgressBar.barRect @(private, init) := fn() { return new Geometry.Rect(0,0,400,32); };
ProgressBar.timer @(private, init) := fn() { return new Util.Timer; };
ProgressBar.maxValue @(private) := 1;
ProgressBar.description @(private) := void;
ProgressBar.bgColor @(private, init) := fn() { return new Util.Color4f(0,0,0,1); };
ProgressBar.barColor @(private, init) := fn() { return new Util.Color4f(0.2,0.2,0.2,1); };
ProgressBar.fgColor @(private, init) := fn() { return new Util.Color4f(1,1,1,1); };

ProgressBar._constructor ::= fn(_usePercentage=true, _computeETR=true, _consoleOutput=true, _clearScreen=true) {
  this.usePercentage = _usePercentage;
  this.computeETR = _computeETR;
  this.consoleOutput = _consoleOutput;
  this.clearScreen = _clearScreen;
};

ProgressBar.update ::= fn(progress) {
  var progPercent = progress/this.maxValue;
  var etr;
  if(computeETR) {    
  	if(progress <= 0)
  		timer.reset();
  	var seconds = progress <= 0 ? 0 : timer.getSeconds() / progPercent - timer.getSeconds();
  	etr =  (seconds/(60*60)).toIntStr() + "h:" + ((seconds/60)%60).toIntStr() + "m:" + (seconds%60).toIntStr() + "s";
  }
  var percentRect = barRect.clone();
  percentRect.width(barRect.width()*progPercent);
  
	var text = "";
  if(description)
    text += description + " ";
  if(usePercentage)
    text += (progPercent*100).toIntStr()+"%";
  else
    text += progress + "/" + maxValue;
  if(computeETR && progress > 0)
   text += " (ETR " + etr + ")";
  if(consoleOutput)
    out("\r", text);
   
	var textRect = frameContext.getTextRenderer().getTextSize(text);
	var textPos = new Geometry.Vec2(barRect.x()+barRect.width()/2-textRect.width()/2,barRect.y()+barRect.height()/2-textRect.height());
  if(clearScreen)
    renderingContext.clearScreen(bgColor);
  else
    renderingContext.clearScreenRect(barRect, bgColor);
	renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);
	renderingContext.pushAndSetLighting(false);
  Rendering.enable2DMode(renderingContext);
	Rendering.drawRect(renderingContext,percentRect, barColor);
	Rendering.drawWireframeRect(renderingContext,barRect, fgColor);
	renderingContext.popLighting();
	renderingContext.popDepthBuffer();
	frameContext.getTextRenderer().draw(renderingContext, text, textPos, fgColor );
  Rendering.disable2DMode(renderingContext);
	PADrend.SystemUI.swapBuffers();
};

ProgressBar.setDescription ::= fn(descr) {
  this.description = descr;
};

ProgressBar.setUsePercentage ::= fn(value) {
  this.usePercentage = value;
};

ProgressBar.setComputeETR ::= fn(value) {
  this.computeETR = value;
};

ProgressBar.setBarRect ::= fn(Geometry.Rect value) {
  this.barRect = value;
};

ProgressBar.setSize ::= fn(Number width, Number height) {
  this.barRect.setSize(width, height);
};

ProgressBar.setPosition ::= fn(Number x, Number y) {
  this.barRect.setPosition(x, y);
};

ProgressBar.setToScreenCenter ::= fn() {
  var vp = renderingContext.getViewport();
  this.barRect.setPosition((vp.width()-barRect.width())/2, (vp.height()-barRect.height())/2);
};

ProgressBar.setMaxValue ::= fn(Number value) {
  assert(value>0);
  this.maxValue = value;
};

ProgressBar.setBgColor ::= fn(Util.Color4f value) {
  this.bgColor = value;
};

ProgressBar.setBarColor ::= fn(Util.Color4f value) {
  this.barColor = value;
};

ProgressBar.setFgColor ::= fn(Util.Color4f value) {
  this.fgColor = value;
};

return ProgressBar; 