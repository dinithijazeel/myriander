class ApplicationController < ActionController::Base
  #
  ## Pundit
  #
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  #
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #
  protect_from_forgery :with => :null_session

  before_action :authenticate_user!

  before_filter :set_current_user
  after_filter -> { flash.discard }, :if => -> { request.xhr? }

  def pdf_generate(view, filename)
    # Generate PDF
    html = render_to_string(
      :template      => view,
      :layout        => 'pdf',
    )
    @save_path = Tempfile.new(['proposal-', '.html'])
    File.open(@save_path, 'wb') do |file|
      file << html
    end
    pdf = render_to_string(
      :pdf           => filename,
      :template      => view,
      :layout        => 'pdf',
      :encoding      => 'UTF-8',
      :background    => true,
      :page_size     => 'Letter',
      :no_pdf_compression => false,
      :margin =>  {
        :top         => 0,
        :bottom      => 0,
        :left        => 0,
        :right       => 0,
      }
    )
    # Save as file
    save_path = Tempfile.new(['proposal-', '.pdf'])
    File.open(save_path, 'wb') do |file|
      file << pdf
    end
    # Return path
    save_path
  end

  def pdf_merge(filepath, components)
    pdf = CombinePDF.new
    components.each do |component|
      pdf << CombinePDF.load(component) unless component.nil?
    end
    pdf.save filepath
  end

  private

  def reorder_params
    params.require(:reorder).permit(:id, :position)
  end

  def set_current_user
    User.current = current_user
  end

  def assign_creator
    self.creator = current_user
  end

  def assign_last_editor
    self.last_editor = current_user
  end

  def helper_reload
    render :inline => 'h.reload();'
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end
end
