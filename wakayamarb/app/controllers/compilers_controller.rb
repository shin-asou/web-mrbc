require "open3"

class CompilersController < ApplicationController

  def rbSourceInput
    @compiler = Compiler.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @compiler }
    end
  end

  def index
    rbSourceInput
  end

  def show
    rbSourceInput
  end

  def new
    rbSourceInput
  end

  def edit
    rbSourceInput
  end

  #Directry All Delete
  def deleteall(delthem)
    if FileTest.directory?(delthem) then
      Dir.foreach( delthem ) do |file|
        next if /^\.+$/ =~ file
        deleteall( delthem.sub(/\/+$/,"") + "/" + file )
      end
      Dir.rmdir(delthem) rescue ""
    else
      File.delete(delthem)
    end
  end

  #Send mrb file
  def send_mrb( pathrbname, opt )
    if(opt.include?("--verbose")==true || opt.include?("-v")==true || opt.include?("-o")==true ) then
      @compiler.destroy
      render action: "new"
      return
    end

    if(opt.include?("--")==true) then
      o, e, s = Open3.capture3("mrbc " + opt + " >&2")
      redirect_to @compiler, notice: e.to_s + ' ' + s.to_s
      @compiler.destroy
      return
    end

    if( pathrbname=='' )then
      o, e, s = Open3.capture3("mrbc -h >&2")
      redirect_to @compiler, notice: e.to_s + ' ' + s.to_s
      @compiler.destroy
      #render action: "new"
      return
    end

    fullpath = Rails.root.to_s + "/public" + File.dirname(pathrbname) + "/"

  	bname = File.basename(pathrbname).downcase
  	if( bname!=File.basename(pathrbname) )then
  		File.rename( fullpath + File.basename(pathrbname), fullpath + bname )
  	end

    rbfile = File.basename(bname)
    mrbfile = File.basename(bname, ".rb") + ".mrb"
    cfile = File.basename(bname, ".rb") + ".c"

    #o, e, s = Open3.capture3("cd " + fullpath + "; mrbc " + opt + " -o" + mrbfile + " " + rbfile + " >&2")
    o, e, s = Open3.capture3("cd " + fullpath + "; mrbc " + opt + " " + rbfile + " >&2")
    if( e==''  ) then
      if( opt.include?("-B")==true )then
        mrb_data = File.binread(fullpath + cfile)
        send_data(mrb_data, filename: cfile, type: "application/octet-stream", disposition: "inline")
      else
        mrb_data = File.binread(fullpath + mrbfile)
        send_data(mrb_data, filename: mrbfile, type: "application/octet-stream", disposition: "inline")
      end
    else
      redirect_to @compiler, notice: e.to_s + ' ' + s.to_s
    end

    @compiler.destroy
    deleteall( fullpath )
  end

  def create
    @compiler = Compiler.new(compiler_params)

    respond_to do |format|
      if @compiler.save
        format.html { send_mrb( @compiler.rb.to_s , @compiler.options.to_s ) }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    rbSourceInput
  end

  def destroy
    @compiler = Compiler.find(params[:id])
    @compiler.destroy

    respond_to do |format|
      format.html { redirect_to compilers_url }
      format.json { head :no_content }
    end
  end

  def compiler_params
    params.require(:compiler).permit(:options, :rb)
  end
end
