AGSScriptModule    Helios Functions for Snow and Rain particle effects SnowRainPS 0.5 `  /*
 * SnowRainPS module script
 * AGS Version: 3.0 and later.
 * Author: Aditya Jaieel (helios123)
 * Version: 1.0
 * Copyright (C) 2010 Aditya Jaieel (helios123)
 *
 * License: 
 * --------
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */


 
#define REGION_COUNT  15 //a room can have a maximum of this many regions
#define MAX_RECT_COUNT 50 //maximum rects that can be created
#define DEF_REGION_LOOP_COUNT 25 //the maximum number of loops the particle can stay visible after entering a region
#define MIN_PARTICLE_LIFE 5 //minimum life in a rect or a region
#define MIN_HEIGHT_ABOVE_BASE 5 //height from bottom for an overlay particle colliding with an object
#define MAX_TRANSPARENCY 75 //maximum transparency a particle can attain
#define MIN_TRANSPARENCY 25 //minimum transparency a particle can attain
#define TRANS_DIFF 50 //MAX_TRANSPARENCY - MIN_TRANSPARENCY
#define MAX_NO_WIND_DEV 3 //x co-ordinate of snow particles will vary by this amount max. when no wind is present.

//Variables
int xcoords[]; //array of x co-ordinates
int ycoords[]; //array of y co-ordinates
int trans[]; //array of transparency of each particle. This changes when the particle enters a region or rect.
int particleType[]; //array of particle types
int particleLifeInRectOrRegion[]; //array number of loops a particle will live after entering a rect or region
int rotAngles[]; //array of angle of rotations
int spriteSlots[]; //array of sprite slot numbers for each particle
int yMin[]; //minimum value of y from where the particles start disappearing
int yMax[]; //maximum value of y from where the particles start disappearing
int xMin[]; //minimum value of x from where the particles start disappearing
int xMax[]; //maximum value of x from where the particles start disappearing
int xIncArray[]; //array of x axis increments
int yIncArray[]; //array of y axis increments
int rotIncArray[]; //array of rotation increments
bool regions[REGION_COUNT]; //array containing status of which regions are to be used for particles for disappearing
int maxLifeInRegion[REGION_COUNT]; //array of maximum number of loops the particle can stay visible after entering a region

function SnowRainPS_Data::SetParticleSystemIncrements(int xIncrement, int yIncrement, int rotIncrement)
{
  if(xIncrement > 0)
  {
    this.xInc = xIncrement;
  }
  if(yIncrement > 0)
  {
    this.yInc = yIncrement;
  }
  if(rotIncrement >= 0)
  {
    this.rotInc = rotIncrement;
  }
  
  int i = 0;
  while(i < this.totalParticleCount)
  {
    xIncArray[i] = 1 + Random(this.xInc - 1);
    yIncArray[i] = 1 + Random(this.yInc - 1);
    rotIncArray[i] = this.rotInc;
    if(this.rotInc > 1)
    {
      rotIncArray[i] = 1 + Random(this.rotInc - 1);
    }
    
    i++;
  }
}

function SnowRainPS_Data::ParticleSystemEnableRegion(int regionID, int lifeInRegion)
{
  if((regionID >=1) && (regionID <= 15))
  {
    regionID--;
    regions[regionID] = true;
    if(lifeInRegion < 0)
    {
      lifeInRegion = DEF_REGION_LOOP_COUNT;
    }
    maxLifeInRegion[regionID] = lifeInRegion;
  }
}

function SnowRainPS_Data::ParticleSystemDisableRegion(int regionID)
{
  if((regionID >=1) && (regionID <= 15))
  {
    regions[regionID - 1] = false;
  }
}

function SnowRainPS_Data::ParticleSystemAddRect(int left, int top, int right, int bottom)
{
  if((left > 0) && (top > 0) && (right > 0) && (bottom > 0) && (this.rectCount < MAX_RECT_COUNT))
  {
    int temp;
    if(left > right)
    {
      temp = left;
      left = right;
      right = temp;
    }
    
    if(top > bottom)
    {
      temp = bottom;
      bottom = top;
      top = temp;
    }
    
    if(right > Room.Width)
    {
      right = Room.Width;
    }
    
    if(bottom > Room.Height)
    {
      bottom = Room.Height;
    }
    
    xMin[this.rectCount] = left;
    xMax[this.rectCount] = right;
    yMin[this.rectCount] = top;
    yMax[this.rectCount] = bottom;
    this.rectCount++;
  }
}

function SnowRainPS_Data::ParticleSystemRemoveLastRect()
{
  if(this.rectCount >= 0)
  {
    this.rectCount--;
  }
}

protected function SnowRainPS_Data::IsObscuredBy(int index)
{
  bool obscured = false;
  
  if(this.collisionDetect)
  {
    Object *objAtXY = Object.GetAtScreenXY(xcoords[index], ycoords[index]);
    Character *charAtXY = Character.GetAtScreenXY(xcoords[index], ycoords[index]);
    
    if((objAtXY != null) && objAtXY.Visible)
    {
      if(index >= this.particleCount)//overlay particle
      {
        obscured = objAtXY.Solid && ((ycoords[index] - objAtXY.Y) < MIN_HEIGHT_ABOVE_BASE);
      }
      else
      {
        obscured = true;
      }
    }
    else if(charAtXY != null)
    {
      obscured = charAtXY.Solid;
    }
  }
  
  return obscured;
}

function SnowRainPS_Data::SetParticleSystemData(SnowRainPS_ParticleSystemType ps, SnowRainPS_WindDirectionType direction)
{
  if(ps != NO_CHANGE_PARTICLE)
  {
    this.systemType = ps;
  }
  if(direction != NO_CHANGE_WIND)
  {
    this.windDirection = direction;
  }
}

function SnowRainPS_Data::SetParticleSystemSpriteData(int slotNumber, int imageCount)
{
  this.newSpriteCount = imageCount;
  this.newSpriteSlot = slotNumber;
}

protected function SnowRainPS_Data::RandomSpriteNumber()
{
  int tempSlot = this.spriteSlot;
  if(this.spriteImages > 1)
  {
    int randomIncrement = Random(this.spriteImages - 1);
      tempSlot += randomIncrement;
  }
  
  return tempSlot;
}

protected function SnowRainPS_Data::UpdateSpritesArray(int index)
{
  if(index >= 0)
  {
    spriteSlots[index] = this.RandomSpriteNumber();
  }
  else
  {
    int i = 0;
    while(i < this.totalParticleCount)
    {
      spriteSlots[i] = this.RandomSpriteNumber();
      i++;
    }
  }
}

protected function SnowRainPS_Data::SetInitialCoordinates(int index, bool ignoreWindDirection)
{
  if(this.active)
  {
    if((xcoords[index] < 0) && (ycoords[index] < 0)) //the co-ordinates were of a particle which was not rendered
    {
      ignoreWindDirection = ((index % 2) == 0); //so ignore the wind direction for some
    }
    xcoords[index] = Random(Room.Width);
    ycoords[index] = Random(Room.Height);
    xIncArray[index] = 1 + Random(this.xInc - 1);
    yIncArray[index] = 1 + Random(this.yInc - 1);
    rotIncArray[index] = this.rotInc;
    if(this.rotInc > 1)
    {
      rotIncArray[index] = 1 + Random(this.rotInc - 1);
    }
    particleLifeInRectOrRegion[index] = -1;
    trans[index] = MIN_TRANSPARENCY;
    
    if(this.systemType == SNOW_AND_RAIN)
    {
      //SNOW = 0, RAIN = 1
      particleType[index] = Random(1);
    }
    else
    {
      particleType[index] = this.systemType;
    }
    
    if(this.rotInc > 0)
    {
      rotAngles[index] = 1 + Random(358);
    }
    else
    {
      rotAngles[index] = 0;
    }
    
    if(!ignoreWindDirection)
    {
      if(this.windDirection == LEFT_TO_RIGHT_DIAGONAL) //make starting point towards the left of the screen
      {
        if(xcoords[index] > ycoords[index])
        {
          xcoords[index] -= ycoords[index];
          ycoords[index] = 0;
        }
        else
        {
          ycoords[index] -= xcoords[index];
          xcoords[index] = 0;
        }
      }
      else if(this.windDirection == RIGHT_TO_LEFT_DIAGONAL) //make starting point towards the right of the screen
      {
        int xdelta = Room.Width - xcoords[index];
        if(xdelta > ycoords[index])
        {
          xcoords[index] += ycoords[index];
          ycoords[index] = 0;
        }
        else
        {
          ycoords[index] -= xdelta;
          xcoords[index] += xdelta;
        }
      }
      else if(this.windDirection == LEFT_TO_RIGHT_HORIZONTAL)//set x co-ordinate to 0
      {
        xcoords[index] = 0;
      }
      else if(this.windDirection == RIGHT_TO_LEFT_HORIZONTAL)//set x co-ordinate to Room.Width
      {
        xcoords[index] = Room.Width;
      }
      else //no wind, so set starting point along the top of the screen
      {
        ycoords[index] = Random(10);
      }
    }
    //set sprite image
    this.UpdateSpritesArray(index);
  }
  else
  {
    xcoords[index] = -1;
    ycoords[index] = -1;
  }
}

function SnowRainPS_Data::SetParticleSystemOverlayPercent(int overlayPerc)
{
  if(overlayPerc < 0)
  {
    overlayPerc = 50;
  }
  else if(overlayPerc > 100)
  {
    overlayPerc = 100;
  }
  
  if(overlayPerc != 0)
  {
    this.overlayCount = this.totalParticleCount*overlayPerc/100;
  }
  else
  {
    this.overlayCount = 0;
  }
  
  this.overlayPerc = overlayPerc;
  this.particleCount = this.totalParticleCount - this.overlayCount;
}

function SnowRainPS_Data::InitParticleSystem(SnowRainPS_ParticleSystemType ps,  int spriteNumber, int numSprites, SnowRainPS_WindDirectionType direction, int numParticles, int overlayPerc, int xIncrement, int yIncrement, int rotIncrement)
{  
  bool doInit = true;
  bool tempBool;
  String errMsg = "ParticleSystem Init failed as:\n";
  
  tempBool = (ps != NO_CHANGE_PARTICLE);
  doInit = doInit && tempBool;
  if(!tempBool)
  {
    errMsg = errMsg.Append(String.Format("Particle system type cannot be NO_CHANGE_PARTICLE in init.\n"));
  }
  
  tempBool = (direction != NO_CHANGE_WIND);
  doInit = doInit && tempBool;
  if(!tempBool)
  {
    errMsg = errMsg.Append(String.Format("Wind direction cannot be NO_CHANGE_WIND in init.\n"));
  }
  
  tempBool = (spriteNumber > 0);
  doInit = doInit && tempBool;
  if(!tempBool)
  {
    errMsg = errMsg.Append(String.Format("Sprite slot %d is not proper.\n", spriteNumber));
  }
  
  if(doInit) //check if a valid sprite is given
  {
    //initialize the variables
    this.SetParticleSystemData(ps,  direction);
    if(numParticles <= 0)
    {
      numParticles = 50; //default if value less than or equal to zero
    }
    
    this.totalParticleCount = numParticles;
    
    this.SetParticleSystemOverlayPercent(overlayPerc);
    
    this.spriteSlot = spriteNumber; //the sprite slot number
    this.spriteImages = 1;
    if(numSprites > 0)
    {
      this.spriteImages = numSprites;
    }
    
    xcoords = new int[numParticles];
    ycoords = new int[numParticles];
    spriteSlots = new int[numParticles];
    rotAngles = new int[numParticles];
    particleType = new int[numParticles];
    particleLifeInRectOrRegion = new int[numParticles];
    trans = new int[numParticles];
    xIncArray = new int[numParticles];
    yIncArray = new int[numParticles];
    rotIncArray = new int[numParticles];
    
    yMax = new int[MAX_RECT_COUNT];
    yMin = new int[MAX_RECT_COUNT];
    xMax = new int[MAX_RECT_COUNT];
    xMin = new int[MAX_RECT_COUNT];
    this.rectCount = 0;
    
    this.theOverlay = null;
    this.bgChanged = false;
    this.active = true;
    this.SetParticleSystemIncrements(xIncrement,  yIncrement, rotIncrement);
    this.collisionDetect = false;
    this.enableTransParency = false;
    this.xincflag = 1;
    
    //create initial co-ordinates
    int i = 0;
    while(i < (this.particleCount+this.overlayCount))
    {
      this.SetInitialCoordinates(i, true);
      i++;
    }
    
    i = 0;
    while(i < REGION_COUNT)
    {
      regions[i] = false;
      i++;
    }
    
    //set pointers
    this.dsRoom = null;
    i = 0;
    while(i < 5)
    {
      this.dsBackup[i] = null;
      i++;
    }
    this.dsSprite = null;
  }
  else
  {
    AbortGame(errMsg.Append("\nPlease check your script."));
  }
}

function SnowRainPS_Data::ShutdownParticleSystem()
{
  if((this.particleCount + this.overlayCount) > 0)
  {
    //remove the overlay
    if(this.theOverlay != null)
    {
      this.theOverlay.Remove();
      this.theOverlay = null;
    }
    
    if(this.theSprite != null)
    {
      this.theSprite.Delete();
      this.theSprite = null;
    }
    
    //restore the background. AGS does this automatically, but only when the room is unloaded.
    if(this.dsBackup[0] != null)
    {
      int i = 0;
      while(i < 5)
      {
        if(this.dsBackup[i] != null)
        {
          this.dsRoom = Room.GetDrawingSurfaceForBackground(i);
          this.dsRoom.DrawSurface(this.dsBackup[i]);
          this.dsBackup[i].Release();
          this.dsRoom.Release();
          this.dsBackup[i] = null;
        }
        i++;
      }
    }
    
    if(this.dsSprite != null)
    {
      this.dsSprite.Release();
      this.dsSprite = null;
    }
    
    //initialize the variables to invalid values, so that a call to InitParticleSystem is required.
    this.particleCount = -1;
    this.spriteSlot = -1;
    this.overlayCount = -1;
    this.newSpriteCount = -1;
    this.newSpriteSlot = -1;
    this.spriteImages = -1;
    this.totalParticleCount = -1;
    this.dsRoom = null;
    this.bgChanged = false;
    this.collisionDetect = false;
    this.rectCount = -1;
    this.active = false;
    this.xInc = 1;
    this.yInc = 1;
    this.rotInc = 0;
  }
}

function SnowRainPS_Data::ChangeRoomBackground(int backgroundNumber)
{
  this.bgChanged = true;
  this.newBgNo = backgroundNumber;
}

protected function SnowRainPS_Data::IsParticleInRoom(int index)
{
  return ((xcoords[index] >= 0) && (ycoords[index] >= 0) && (xcoords[index] <= Room.Width) && (ycoords[index] <= Room.Height));
}

protected function SnowRainPS_Data::IsParticleInRect(int index)
{
  bool inRect = false;
  
  if((this.rectCount > 0) && (index < this.totalParticleCount))
  {
    int i = 0;
    while((!inRect) && (i < this.rectCount))
    {
      inRect = ((xcoords[index] >= xMin[i]) && (xcoords[index] <= xMax[i]) && (ycoords[index] >= yMin[i]) && (ycoords[index] <= yMax[i]));
    
      if(inRect)
      {
        if(particleLifeInRectOrRegion[index] == -1)
        {
          particleLifeInRectOrRegion[index] = MIN_PARTICLE_LIFE + Random(yMax[i] - yMin[i]-MIN_PARTICLE_LIFE);
          if(index >= this.particleCount) //it is an overlay particle
          {
            particleLifeInRectOrRegion[index] += (yMax[i] - yMin[i])/2;
          }
        }
        
        //update transparency
        if(this.enableTransParency && (particleLifeInRectOrRegion[index] < TRANS_DIFF))
        {
          trans[index]++;
        }
        
        particleLifeInRectOrRegion[index]--;
        inRect = (particleLifeInRectOrRegion[index] == 0);
        //since this particle is already tagged to a rect, break out of the loop
        i = this.rectCount;
      }
            
      i++;
    }
  }
  return inRect;
}

protected function SnowRainPS_Data::IsParticleInRegion(int index)
{
  bool inRegion = false;
  
  if(index < this.totalParticleCount)
  {
    /*
     * here it is important to note that regions[0] is the status for region id 1,
     * regions[1] is the status for region id 2, and so on.
     */
    Region *current_region = Region.GetAtRoomXY(xcoords[index], ycoords[index]);
    
    if(current_region.ID > 0) //check if region is active
    {
      inRegion = regions[current_region.ID-1];
    }

    if(inRegion)
    {
      if(particleLifeInRectOrRegion[index] == -1)
      {
        particleLifeInRectOrRegion[index] = MIN_PARTICLE_LIFE + Random(maxLifeInRegion[current_region.ID-1]-MIN_PARTICLE_LIFE);
        if(index >= this.particleCount) //it is an overlay particle
        {
          particleLifeInRectOrRegion[index] += maxLifeInRegion[current_region.ID-1]/2;
        }
      }
     
      //update transparency
      if(this.enableTransParency && (particleLifeInRectOrRegion[index] < TRANS_DIFF))
      {
        trans[index]++;
      }
        
      particleLifeInRectOrRegion[index]--;
      inRegion = (particleLifeInRectOrRegion[index] == 0);
      //since this particle is already tagged to a region, break out of the loop
    }
  }
  return inRegion;
}

protected function SnowRainPS_Data::UpdateCoords(int index)
{
  if((xcoords[index] >= 0) && (ycoords[index] >= 0)) //this will be true for particles to be rendered
  {
    //Update rotation. Not logical for rain.    
    if((this.rotInc > 0) && (particleType[index] == SNOW))
    {
      rotAngles[index] = ((rotAngles[index] + rotIncArray[index])%359);
      if(rotAngles[index] == 0)
      {
        rotAngles[index] = 1;
      }
    }
    
    //if((this.xInc > 0) && (this.yInc > 0)) //update the co-ordinates
    {
      if((this.windDirection == LEFT_TO_RIGHT_DIAGONAL) || (this.windDirection == LEFT_TO_RIGHT_HORIZONTAL))
      {
        if(particleType[index] == SNOW)
        {
          xcoords[index] += Random(xIncArray[index]); //x co-ordinate always increases
        }
        else
        {
          xcoords[index] += xIncArray[index]; //x co-ordinate always increases
        }
      }
      else if((this.windDirection == RIGHT_TO_LEFT_DIAGONAL) || (this.windDirection == RIGHT_TO_LEFT_HORIZONTAL))
      {
        if(particleType[index] == SNOW)
        {
          xcoords[index] -= Random(xIncArray[index]); //x co-ordinate always decreases
        }
        else
        {
          xcoords[index] -= xIncArray[index]; //x co-ordinate always decreases
        }
      }
      else //if wind direction is none
      {
        if(particleType[index] == SNOW)
        {
          xcoords[index] += (this.xincflag * Random(xIncArray[index]) % MAX_NO_WIND_DEV);
        }
        //if wind direction is none, then no need to do anything to x co-ordinate 
      }  

      if((this.windDirection != LEFT_TO_RIGHT_HORIZONTAL) && (this.windDirection != RIGHT_TO_LEFT_HORIZONTAL))
      {
        //This does not look realistic. Uncomment if required
        /*if(particleType[index] == SNOW)
        {
          ycoords[index] += Random(yIncArray[index]); //to give the floating effect
        }
        else*/
        {
          ycoords[index] += yIncArray[index]; //y co-ordinate always increases
        }
      }
    }
  }
  if(this.IsParticleInRect(index) || this.IsParticleInRegion(index) || (!this.IsParticleInRoom(index)) || this.IsObscuredBy(index))
  {
    this.SetInitialCoordinates(index, false);
  }
}

function SnowRainPS_Data::RenderParticles()
{
  if(this.totalParticleCount > 0)
  {    
    if(this.bgChanged) //update background if required
    {
      SetBackgroundFrame(this.newBgNo);
      this.bgChanged = false;
    }
    
    //update sprite slot number and number of sprites if changed
    if(this.newSpriteCount > 1)
    {
      if(this.newSpriteCount != this.spriteImages)
      {
        this.spriteImages = this.newSpriteCount;
        this.newSpriteCount = -1;
      }
      else
      {
        this.newSpriteCount = -1;
      }
    }
    
    if(this.newSpriteSlot > 1)
    {
      if(this.newSpriteSlot != this.spriteSlot)
      {
        this.spriteSlot = this.newSpriteSlot;
        this.newSpriteSlot = -1;
      }
      else
      {
        this.newSpriteSlot = -1;
      }
    }
    
    int currentFrame = GetBackgroundFrame();
    this.dsRoom = Room.GetDrawingSurfaceForBackground(currentFrame); //get room's background
    
    //this copies (or creates) the appropriate backup copy to remove the old frame
    //This also works when AGS cycles through the rooms backgrounds.
    //Note that calling SetBackgroundFrame from a different script may not always work, as order of
    //execution is not guaranteed.
    if(this.dsBackup[currentFrame] != null)
    {
      this.dsRoom.DrawSurface(this.dsBackup[currentFrame]);
    }
    else
    {
      this.dsBackup[currentFrame] = this.dsRoom.CreateCopy();
    }
    
    //if(this.active) //draw sprites only if active flag is true
    {
      //the drawing logic
      if(this.theSprite != null)
      {
        this.theSprite.Delete();
        //this.theSprite = null;
      }
      this.theSprite = DynamicSprite.Create(Room.Width, Room.Height);
      
      if(this.dsSprite != null)
      {
        this.dsSprite.Release();
        this.dsSprite = null;
      }
      this.dsSprite = this.theSprite.GetDrawingSurface();
      int i = 0;
      this.xincflag = (-1 * this.xincflag); //to create the wavy effect of falling
      while( i < this.totalParticleCount)
      {
        DynamicSprite *spriteImage = DynamicSprite.CreateFromExistingSprite(spriteSlots[i], true);
        spriteImage.Tint(50, 50, 50, 30, 25);
        //rotate only snow particles
        if((rotAngles[i] > 0) && (particleType[i] == SNOW))
        {
          spriteImage.Rotate(rotAngles[i]);
        }
        if((xcoords[i] >= 0) && (ycoords[i] >= 0))
        {
          if(i < this.particleCount) //draw on room background
          {
            this.dsRoom.DrawImage(xcoords[i], ycoords[i], spriteImage.Graphic, trans[i], spriteImage.Width, spriteImage.Height);
            
            //if system is rain and snow, and particle is rain, then draw more images to make the particle look
            //like a rain particle
            //trans[i] will depend upon whether enableTransparency is true or false
            if((this.systemType == SNOW_AND_RAIN) && (particleType[i] == RAIN))
            {
              this.dsRoom.DrawImage(xcoords[i], ycoords[i]-spriteImage.Height, spriteImage.Graphic, trans[i], spriteImage.Width, spriteImage.Height);
              this.dsRoom.DrawImage(xcoords[i], ycoords[i]+spriteImage.Height, spriteImage.Graphic, trans[i], spriteImage.Width, spriteImage.Height);
            }
          }
          else //draw on dynamic sprite
          {
            //delete 0 and uncomment trans[i] to enable transparency on overlays.
            
            this.dsSprite.DrawImage(xcoords[i], ycoords[i], spriteImage.Graphic, 0/*trans[i]*/, spriteImage.Width, spriteImage.Height);
            
            //if system is rain and snow, and particle is rain, then draw more images to make the particle look
            //like a rain particle
            if((this.systemType == SNOW_AND_RAIN) && (particleType[i] == RAIN))
            {
              this.dsSprite.DrawImage(xcoords[i], ycoords[i]-spriteImage.Height, spriteImage.Graphic, 0/*trans[i]*/, spriteImage.Width, spriteImage.Height);
              this.dsSprite.DrawImage(xcoords[i], ycoords[i]+spriteImage.Height, spriteImage.Graphic, 0/*trans[i]*/, spriteImage.Width, spriteImage.Height);
            }
          }
        }
        spriteImage.Delete();
        
        this.UpdateCoords(i);
        
        i++; //go to next particle's co-ordinates
      }
    }
    if(this.dsRoom != null)
    {
      this.dsRoom.Release(); //release the room's background
      this.dsRoom = null;
    }
    if(this.dsSprite != null)
    {
      this.dsSprite.Release(); //release the dynamic sprite's background
      this.dsSprite = null;
    }
    
    //draw the dynamic sprite onto a graphical ovarlay
    if((this.theOverlay != null) && this.theOverlay.Valid)
    {
      this.theOverlay.Remove();
      this.theOverlay = null;
    }
    if(this.theSprite != null)
    {
      this.theOverlay = Overlay.CreateGraphical(0, 0, this.theSprite.Graphic, true);
      this.theSprite.Delete();
      this.theSprite = null;
    }
  }
} �F  /*
 * SnowRainPS module script
 * AGS Version: 3.0 and later.
 * Author: Aditya Jaieel (helios123)
 * Version: 1.0
 * Copyright (C) 2010 Aditya Jaieel (helios123)
 *
 * Module Info:
 * ------------
 * This module will generate snow/rain effect.
 * It makes use of the room background's drawing surface as well as graphical overlay to achieve this.
 * The overlay gives the effect of snow/rain falling in front of the character, object, etc.
 *
 * The idea behind providing a separate function is to allow the user more control rendering of particles
 * based on certain conditions, etc.
 *
 * NOTE: Only one effect can be used at a time.
 *
 * IMPORTANT: 1) Try to avoid calling Room.SetBackgroundFrame from some other script when this module is being used, 
 *               as it may cause problems. Instead, the ChangeRoomBackground function provided in this module may
 *               be used.
 *               The default background cycling logic of AGS should not cause any problems.
 *            2) This script creates one overlay.
 *               There is a limit to the number of overlays that can be created (maximum 20).
 *            3) For best results, ensure that the color depth of the sprite and game is the same.
 *            4) Transparency may not work properly on overlays. Hence, it is disabled for overlay particles. 
 *               See line 766 in SnowRain.asc.
 *
 * Changelog:
 * ----------
 * v0.1: Initial
 * v0.2: Updated use of overlays based on ParticleSystemManager by Miguel Garc�a D�az (Jerakeen)
 * v0.3: Added ability to add/remove rectangles/room regions for particles to disappear.
 *       Added SetParticleSystemOverlayPercent to control the percentage of particles drawn on the overlay.
 *       Added facility to provide rotation for particles if required.
 * v0.4: Added logic for removing background particles obscured by character or object
 * v0.5: Moved all exported functions inside a struct to prevent name collisions. Moved some configuration
 *       parameters as struct properties
 * v1.0: Updated logic in IsParticleInRect and IsParticleInRegion to set particle life in rect/region.
 *       IsParticleInRect and IsParticleInRegion now affect all particles.
 *       New System type: SNOW_AND_RAIN. (experimental)
 *       xInc, yInc and rotInc are now READ ONLY.
 *       Collision Detection now uses the Solid property of object and character to check for collision.
 *       Character.Solid and Object.Solid has to be true for collision detection to work.
 *       Everything except arrays is now moved in the struct.
 *       Transparency. Each background particle is MIN_TRANSPARENCY (25 percent) transparent. 
 *       Background particles slowly become more transparent after entering a region or rect.
 *
 *
 * License: 
 * --------
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */

// Check for correct AGS version
#ifdef AGS_SUPPORTS_IFVER
#ifnver 3.00
#error Module SnowRainPS requires AGS V3.00 or above
#endif
#endif

/* SetInitialCoordinates requires SNOW=0 and RAIN=1.
 * Any change below should be accompanied by a proper change in SetInitialCoordinates.
 */
enum SnowRainPS_ParticleSystemType  //The type of the system
{
  SNOW, 
  RAIN,
  SNOW_AND_RAIN, 
  NO_CHANGE_PARTICLE
};

enum SnowRainPS_WindDirectionType //The type of wind
{
  LEFT_TO_RIGHT_DIAGONAL,
  LEFT_TO_RIGHT_HORIZONTAL, 
  RIGHT_TO_LEFT_DIAGONAL,
  RIGHT_TO_LEFT_HORIZONTAL, 
  NONE, 
  NO_CHANGE_WIND
};

struct SnowRainPS_Data
{
  /*
   * true when the particle system is active, false otherwise. This is also updated by the functions, 
   * setting this to false will stop the rendering of particles if the system is running.
   * This can be used for pause/unpause like behavior.
   */
  bool active;
  
  /*
   * The new sprite slot number. 
   * Use this to change the starting sprite number for drawing the particles, while the system is running.
   * This attribute is ignored by InitParticleSystem.
   * See also SetParticleSystemSpriteData.
   */
  int newSpriteSlot;
  
  /*
   * The new sprite count.
   * Use this to change the number of sprite images used, while the system is running.
   * This attribute is ignored by InitParticleSystem.
   * See also SetParticleSystemSpriteData
   */
  int newSpriteCount;
  
  /*
   * Sets the collision detection flag.
   * If set to true, all background particles will be removed when they come in contact with any object
   * or character in the room.
   *
   * WARNING: If the room has a lot of objects, or characters, or particles, this might slow the game down.
   */
  bool collisionDetect;
  
  /*
   * Enables transparency.
   * If set to true, all particles will slowly become transparent once they enter a rect or region.
   * Default is false.
   * Transparency does not appear to work well with overlays. So transparency will be applied only to background
   * particles.
   */
  bool enableTransParency;
  
  /*
   * Initializes the particle system. This method should be called before using the particle system.
   * Place this method in the function that runs when the room loads.
   * This method can be called repeatedly, even when the system is running. This can be used to simulate
   * sudden climate changes.
   * Passing negative value for any integer parameter will result in the defaults being used.
   *
   * Arguments:
   * ps - the type of particle system (cannot be NO_CHANGE_PARTICLE)
   * spriteNumber - the sprite slot number (must be greater than 0)
   * numSprites - the number of sprites to use (default is 1). This is combined with spriteNumber as follows:
   * If spriteNumber is 2 and numSprites is 5, then images in slot numbers from 2 to (2+5-1=)6, both 2 and 6 inclusive
   * will be used.
   * windDirection - the nature of wind (default is NONE. This cannot be NO_CHANGE_WIND)
   * numParticles - the total number of particles required (default is 50).
   * overlayPerc - percentage of the total number of particles to be drawn on the overlay (default is 50)
   * xIncrement - amount in pixels by which the x co-ordinate of each particle should change between two successive states (default is 1)
   * yIncrement - amount in pixels by which the y co-ordinate of each particle should change between two successive states (default is 1)
   * rotIncrement - amount in degrees by which the particle is rotated between two successive states (default is 0)
   */
  import function InitParticleSystem(SnowRainPS_ParticleSystemType ps,  int spriteNumber, int numSprites = 1, SnowRainPS_WindDirectionType windDirection = NONE, int numParticles = 50, int overlayPerc=50, int xIncrement = 1, int yIncrement = 1,  int rotIncrement = 0);
  
  /*
   * Renders the particles on the screen. Call this in the room's repeatedly execute 
   * (or repeatedly execute always) function.
   */
  import function RenderParticles();
  
  /*
   * Shuts down the particle system.
   * Call this function when the room unloads or when you want to stop the effect.
   */
  import function ShutdownParticleSystem();
  
  /*
   * Method to change the room's background. This can be used as an alternative to Room.SetBackgroundFrame.
   *
   * Arguments:
   * backgroundNumber - the new background number
   */
  import function ChangeRoomBackground(int backgroundNumber);
  
  /*
   * Sets the increments in co-ordinates of x and y axes. Use this to change the increments when the system is running
   * Passing 0 or a negative value will not update the corresponding increment value.
   * Passing 0 for the rotation increment will effectively stop rotation.
   * These values will be immediately after this function is called.
   *
   * NOTE: The increment values are always positive. The wind direction will determine how they are used to modify
   *       the co-ordinates.
   *
   * Arguments:
   * xIncrement - amount in pixels by which the x co-ordinate of each particle should change between two successive states (default is 1)
   * yIncrement - amount in pixels by which the y co-ordinate of each particle should change between two successive states (default is 1)
   * rotIncrement - the amount of rotation in degrees between two successive states (default is 0)
   */
  import function SetParticleSystemIncrements(int xIncrement = 1, int yIncrement = 1, int rotIncrement = 0);
  
  /*
   * Sets the type of particle system and wind direction. Use this to change the details when the system is running.
   *
   * Arguments:
   * ps - the type of particle system
   * windDirection - the nature of wind (default is NO_CHANGE_WIND)
   *
   * Passing corresponding NO_CHANGE_ option for any parameter will retain the existing setting.
   */
  import function SetParticleSystemData(SnowRainPS_ParticleSystemType ps, SnowRainPS_WindDirectionType direction = NO_CHANGE_WIND);
  
  /*
   * Changes the starting sprite slot and number of images used.
   * If any parameter is less than 1, it will be ignored.
   * Any new particle created after this function call will use the data passed in arguments.
   *
   * Arguments:
   * slotNumber - the slot number of the first sprite
   * imageCount - the number of sprites (default is 1)
   *
   * This is used as follows:
   * If slotNumber is 2 and imageCount is 5, then images in slot numbers from 2 to (2+5-1=)6, both 2 and 6 inclusive
   * will be used.
   */
  import function SetParticleSystemSpriteData(int slotNumber, int imageCount = 1);
  
  /*
   * Changes the percentage of particles on the overlay.
   *
   * Arguments:
   * overlayPerc - the percentage of particles to put on overlay (default is 50).
   */
  import function SetParticleSystemOverlayPercent(int overlayPerc=50);
  
  /*
   * Adds a rectangle where a particle may disappear.
   * This can be used to create the effect of ground or some other surface.
   * For regions that are not rectangles, create a region in the room editor 
   * and pass its id to ParticleSystemEnableRegion function.
   * A maximum of MAX_RECT_COUNT (which is 50) rectangles can be added. (This may change later)
   * 
   * Arguments:
   * left - x co-ordinate of top left corner of the rectangle
   * top - y co-ordinate of the top left corner of the rectangle
   * right - x co-ordinate of bottom right corner of the rectangle
   * bottom - y co-ordinate of the bottom right corner of the rectangle
   *
   * NOTE: All values must be greater than zero, otherwise the rectangle will not be added.
   * This will only apply to particles drawn on the background. So make sure that overlayPercent is not 100.
   */
  import function ParticleSystemAddRect(int left, int top, int right, int bottom);
  
  /*
   * Removes the last rectangle added using ParticleSystemAddRect
   */
  import function ParticleSystemRemoveLastRect();
  
  /*
   * Makes a particular room region active for particles to disappear on.
   * It is suggested that regions should be used for irregularly shaped areas, or areas which cannot be
   * represented as a rect, e.g. roof of a house, treetops, etc.
   *
   * Arguments:
   * regionID - the id of the region. Any value less than 1 and greater than 15 will be ignored.
   * lifeInRegion - the maximum number of loops for which a particle can remain visible after entering a region
   * (default is 25). 
   *
   * This is used as follows:
   * Each particle has a value named 'particleLifeInRectOrRegion' associated with it, which is basically the 
   * number of loops the particle remains visible after entering a region (or a rect). This is initially -1.
   * Suppose lifeInRegion for a particular region id 2 is 30. Now when the particle arrives in a region
   * (or a rect), it is first checked whether particleLifeInRectOrRegion is -1 for that particle.
   * If it is, then it is assigned a random number between MIN_PARTICLE_LIFE (which is 5) and 
   * lifeInRegion. Then this is decremented by 1 every time the particle is drawn on the screen. 
   * When particleLifeInRectOrRegion becomes zero, the particle is removed from the screen.
   *
   * The lifeInRegion argument is redundant in ParticleSystemAddRect as it can be readily calculated as the difference
   * between the two y co-ordinates of the rectangle. However, this is not possible in regions, and hence a separate
   * argument is needed.
   */
  import function ParticleSystemEnableRegion(int regionID, int lifeInRegion = 25);
  
  /*
   * Makes a particular room region inactive for particles to disappear on.
   *
   * Arguments:
   * regionID - the id of the region. Any value less than 1 and greater than 15 will be ignored.
   */
  import function ParticleSystemDisableRegion(int regionID);
  
  
  /*
   * The maximum possible increments for x, y and rotation. These are read only.
   * Use SetParticleSystemIncrements to set these values.
   */
  writeprotected int xInc; //increment on x-axis
  writeprotected int yInc; //increment on y-axis
  writeprotected int rotInc; //rotation increment in degrees
  
  /*
   * The percentage of particles to put on overlay. This is for information purpose only.
   * Changing this property is not allowed. To change the overlay percent, use SetParticleSystemOverlayPercent.
   */
  writeprotected int overlayPerc;
  
  
  /**********************PRIVATE DATA AND FUNCTIONS**********************/
  
  /*
   * Checks if a particle is in a rect. Returns true when the particle is to be removed from the rect.
   * This will apply to all particles.
   *
   * Arguments:
   * index - the index of the particle
   *
   * Returns:
   * true or false if particle is to be removed from room, else false
   */
  protected import function IsParticleInRect(int index);
  
  /*
   * Checks if a particle is in the room
   *
   * Arguments:
   * index - the index of the particle
   *
   * Returns:
   * true if particle is in room, else false
   */
  protected import function IsParticleInRoom(int index);
  
  /*
   * Internal function to check whether a particle is obscured by a room character or object
   * or object
   */
  protected import function IsObscuredBy(int index);
  
  /*
   * returns a sprite number
   */
  protected import function RandomSpriteNumber();
  
  /*
   * Updates the sprites array.
   * Arguments:
   * index - the index in the array to update. If this is less than 0, the entire array is updated.
   */
  protected import function UpdateSpritesArray(int index);
  
  /*
   * Sets the initial x and y co-ordinates based on the wind direction.
   * Also sets the sprite image and the initial rotation
   *
   * Arguments:
   * index - the array index to update
   * ignoreWindDirection - if true, the wind direction is not considered while generating the coordinares.
   */
  protected import function SetInitialCoordinates(int index, bool ignoreWindDirection);
  
  /*
   * Checks if a particle is in any region where particles can disappear.
   * Returns true when the particle is to be removed from the rect.
   * This will apply to all particles.
   *
   * Arguments:
   * index - the index of the particle
   *
   * Returns:
   * true if particle is to be removed from region, else false
   */
  protected import function IsParticleInRegion(int index);
  
  /*
   * Internal function to update co-ordinates for particle system
   *
   * Arguments:
   * index - the index of the array to update
   */
  protected import function UpdateCoords(int index);
  
  
  protected int rectCount; //the number of rectangles where particles can disappear
  protected bool bgChanged; //set to true by ChangeRoomBackground. Used to update the room's background.
  protected int xincflag; //multiplier for x axis
  //protected int yincflag ; //multiplier for y axis (not needed as of now)
  protected int spriteSlot; //the number of sprite to be used
  protected int spriteImages; //the number of sprite images
  protected int particleCount; //the number of particles that will be drawn on the room background
  protected int overlayCount; //the number of particles on the overlay
  protected int totalParticleCount; //the total number of particles
  protected int newBgNo; //the new room background. Used to update the room's background.
  
  protected SnowRainPS_ParticleSystemType systemType; //the type of particle system
  protected SnowRainPS_WindDirectionType windDirection; //the wind direction
  
  protected DrawingSurface* dsRoom; //pointer to the DrawingSurface for room background
  protected DrawingSurface* dsBackup[5]; //pointer to store original unchanged background
  protected DrawingSurface* dsSprite; //used for drawing to the dynamic sprite
  protected Overlay *theOverlay; //overlay
  protected DynamicSprite *theSprite; //sprite to be drawn on the overlay
  
};
 �I}        ej��