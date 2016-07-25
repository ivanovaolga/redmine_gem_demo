class CompetencesController < ApplicationController
  unloadable

  before_filter :require_admin
  before_filter :set_competence,  only: [:edit, :update, :destroy]
  before_filter :set_system,      only: [:index, :new]

  def index
    @competences  = Competence.where(system: @system).order(:month)
  end

  def new
    @competence = Competence.new(system: @system)
  end

  def create
    @competence = Competence.new(params[:competence])
    if @competence.save
      redirect_to competences_system_path, notice: l(:new_competence_value_added)
    else
      render :new
    end
  end

  def update
    if @competence.update_attributes(params[:competence])
      redirect_to competences_system_path, notice: l(:competence_value_edited)
    else
      render :edit
    end
  end

  def destroy
    @competence.destroy
    redirect_to competences_system_path, notice: l(:competence_value_deleted)
  end

  private

  def set_competence
    @competence = Competence.find(params[:id])
  end

  def set_system
    @system = params[:system]
  end

  def competences_system_path
    competences_path(system: @competence.system)
  end
  helper_method :competences_system_path
end
