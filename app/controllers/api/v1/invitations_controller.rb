module Api
  module V1
    class InvitationsController < ApplicationController
      skip_before_action :verify_authenticity_token
      respond_to :json

      # GET /invitations
      def index
        render status: 200,
               json: { message: 'all invitations' } and return
      end

      # POST /invitations
      def create
        @invitation = Invitation.where(invitee_email: invitation_params[:invitee_email]).first

        if @invitation
          @invitation.resend_invite!

          render status: 302, 
                 json: { message: "Found existing invitation. Invitation was resent." } and return
        elsif @invitation.nil?
          @invitation = Invitation.new(invitation_params)
          @invitation.medium = 'api'
          @invitation.code_of_conduct = true

          if (invitation_params.has_key?(:slack_uid) && !invitation_params[:slack_uid].blank?)
            user = User.find_user_by_slack_uid(invitation_params[:slack_uid])
            @invitation.user = user if user
          else
            render status: 405,
                   json: { message: "Invalid input" } and return
          end

          if @invitation.save
            @invitation.send_invite!

            render status: :created, 
                   json: { message: "Created" } and return
          else
            render status: 422,
                   json: { message: @invitation.errors } and return
          end
        else
          render status: 500,
                 json: { message: "An error has occured" } and return
        end
      end

      private
        # Only allow a trusted parameter "allowed list" through.
        def invitation_params
          params.require(:invitation).permit(:slack_uid, :invitee_name,
                                             :invitee_email, :invitee_title,
                                             :invitee_company, :invitation)
        end
    end
  end
end
